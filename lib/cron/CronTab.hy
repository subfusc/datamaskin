;; -*- coding: utf-8 -*-
(import [threading [Thread Lock Timer]])
(import traceback)
(import time)
(import sys)
(import [.CronList [CronList]])

(defmacro with-lock [lock expr]
  `(do
     (.acquire ~lock)
     (try ~expr
          (finally (.release ~lock)))))

(defmacro with-lock-unchecked-release [lock expr]
  `(do
     (.acquire ~lock)
     (try ~expr
          (finally (if (.locked ~lock) (.release ~lock))))))

(defclass CronTab [Thread]
  "A CronTab, running something on a given time, for datamaskin"

  (defn --init-- [self messaging-function]
    (.--init-- (super CronTab self))
    (setv
      self.--job-list (CronList)
      self.--external-synchronization (Lock)
      self.--job-wait-lock (Lock)
      self.--timer None
      self.--exit False
      self.--messaging-function messaging-function))

  (defn --len-- [self]
    (len self.--job-list))

  (defn at [self key]
    (.at self.--job-list key))

  (defn --str-- [self] (str self.--job-list))

  (defn add-job [self job]
    (with-lock self.--external-synchronization
      (do
        (.add self.--job-list job)
        (if (and self.--timer (.is_alive self.--timer))
            (.cancel self.--timer))
        (if (.locked self.--job-wait-lock) (.release self.--job-wait-lock))))
    job.id)

  (defn del-job [self uuid]
    (with-lock self.--external-synchronization
      (.del self.--job-list uuid)))

  (defn stop [self]
    (with-lock self.--external-synchronization
      (do
        (setv self.--exit True)
        (if (and self.--timer (.is_alive self.--timer)) (.cancel self.--timer))
        (.release self.--job-wait-lock))))

  (defn clear [self]
    (with-lock self.--external-synchronization
      (.clear self.--job-list)))

  (defn --repr-- [self] (repr self.--job-list))

  (defn run [self]
    (while (not self.--exit)
      (if (> (len self.--job-list) 0)
          (do
            (with-lock self.--external-synchronization
              (if (> (len self.--job-list) 0)
                  (do
                    (.acquire self.--job-wait-lock)
                    (setv self.--timer (Timer
                                         (- (. (.peek self.--job-list) next-run) (.time time))
                                         (fn [lock] (if (.locked lock) (.release lock)))
                                         [self.--job-wait-lock]))
                    (.start self.--timer))))
            (with-lock-unchecked-release self.--job-wait-lock
              (do
                (setv next-job (.borrow self.--job-list))
                (if (and next-job (< next-job.next-run (.time time)))
                    (try
                      (self.--messaging-function
                        (next-job.function #* next-job.args)
                        next-job.context)
                      (except [e Exception]
                        (.del self.--job-list next-job.uuid)
                        (traceback.print-exc)
                        (print (.format "Error in the Crontab: {}" (repr e)) :file sys.stderr))
                      (finally (.continue self.--job-list)))
                    (.unborrow self.--job-list)))))
          (with-lock-unchecked-release self.--job-wait-lock
            (.acquire self.--job-wait-lock))))))
