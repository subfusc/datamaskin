(import [.PluginBot [PluginBot]])
(import [uuid [UUID uuid4]])
(import [threading [Thread Lock Timer]])
(import time)
(import os)
(import sys)
(import traceback)
(import [math [ceil]])

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

(defclass CronJob []
  (defn --init-- [self time function args context]
    (setv
      self.id (uuid4)
      self.time time
      self.function function
      self.args args
      self.context context))

  (defn --repr-- [self]
    f"<job {(repr self.id)}: {self.time}>"))

(defclass CronList []
  (defn --init-- [self]
    (setv self.--tab [])
    (setv self.--lock (Lock)))

  (defn --len-- [self]
    (len self.--tab))

  (defn add [self job]
    (with-lock self.--lock
      (do
        (setv insert-at None)
        (for [[index stored-job] (enumerate self.--tab)]
          (if (> job.time stored-job.time) (do (setv insert-at index) (break)))
          (else (.append self.--tab job)))
        (if (!= insert-at None) (.insert self.--tab insert-at job)))))

  (defn del [self uuid]
    (with-lock self.--lock
      (do
        (setv i 0)
        (for [[index stored-job] (enumerate self.--tab)]
          (if (= uuid stored-job.id) (do (setv i index) (break))))
        (del (get self.--tab i)))))

  (defn peek [self]
    (get self.--tab -1))

  (defn pop [self]
    (with-lock self.--lock
      (.pop self.--tab))))

(defclass CronTab [Thread]
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

  (defn add-job [self job]
    (with-lock self.--external-synchronization
      (do
        (.add self.--job-list job)
        (if (and self.--timer (.is_alive self.--timer))
            (.cancel self.--timer))
        (if (.locked self.--job-wait-lock) (.release self.--job-wait-lock))))
    job.id)

  (defn del-job [self uuid]
    (.del self.--job-list uuid))

  (defn stop [self]
    (with-lock self.--external-synchronization
      (do
        (setv self.--exit True)
        (if (and self.--timer (.is_alive self.--timer)) (.cancel self.--timer))
        (.release self.--job-wait-lock))))

  (defn run [self]
    (while (not self.--exit)
      (print f"Checking for new job" :file sys.stderr :flush True)
      (if (> (len self.--job-list) 0)
          (do
            (with-lock self.--external-synchronization
              (do
                (.acquire self.--job-wait-lock)
                (setv self.--timer (Timer
                                     (- (. (.peek self.--job-list) time) (.time time))
                                     (fn [lock] (if (.locked lock) (.release lock)))
                                     [self.--job-wait-lock]))
                (.start self.--timer)))
            (with-lock-unchecked-release self.--job-wait-lock
              (if (> (len self.--job-list) 0)
                  (do
                    (setv next-job (.pop self.--job-list))
                    (if (and next-job (< next-job.time (.time time)))
                    (try
                      (self.--messaging-function
                        (next-job.function #* next-job.args)
                        next-job.context)
                      (except [e Exception]
                        (traceback.print-exc)
                        (print (.format "Error in the Crontab: {}" (repr e)) :file sys.stderr)))
                    (.add self.--job-list next-job))))))
          (with-lock-unchecked-release self.--job-wait-lock
            (.acquire self.--job-wait-lock))))))

(defclass CronBot [PluginBot]
  (defn --init-- [self config]
    (.--init-- (super) config)
    (setv self.--tab (CronTab self.-send-message))
    (.start self.--tab))

  (defn add-jobs-to-kwarg [self context kwargs]
    (setv
      (get kwargs "new_job")
      (fn [time function args] (.add-job self.--tab (CronJob time function args context)))
      (get kwargs "del_job")
      (fn [uuid] (.del-job self.--tab uuid))))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (.add-jobs-to-kwarg self context kwargs)
    (.cmd (super CronBot self) command args :context context #** kwargs))

  (defn listen [self message &optional [context '()] &kwargs kwargs]
    (.add-jobs-to-kwarg self context kwargs)
    (.listen (super CronBot self) message :context context #** kwargs)))

(defmain [&rest _]
  (.start (CronBot {"nick" "Test"
                    "command_prefix" "!"
                    "plugins" ["Useless" "Reminder"]})))
