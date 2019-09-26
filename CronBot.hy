(import [PluginBot [PluginBot]])
(import [uuid [UUID uuid4]])
(import [threading [Thread Lock Timer]])
(import time)
(import os)
(import sys)
(import [math [ceil]])

(defmacro with-lock [lock &rest expr]
  `(do
     (.acquire ~lock)
     (try ~expr
          (finally (.release ~lock)))))

(defmacro with-lock-unchecked-release [lock &rest expr]
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
      self.context context)))

(defclass CronList []
  (defn --init-- [self]
    (setv self.--tab [])
    (setv self.--lock (Lock)))

  (defn --len-- [self]
    (len self.--tab))

  (defn add [self job]
    (with-lock self.--lock
      (for [[index stored-job] (enumerate self.--tab)]
        (if (> job.time stored-job.time)
            (.insert self.--tab index job))
        (else (.append self.--tab job)))))

  (defn del [self uuid]
    (with-lock self.--lock
      (for [[index stored-job] (enumerate self.--tab)]
        (if (= uuid stored-job.uuid)
            (do (del (get self.--tab index)) (break))))))

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
      (.add self.--job-list job)
      (if (and self.--timer (.is_alive self.--timer))
          (.cancel self.--timer))
      (if (.locked self.--job-wait-lock) (.release self.--job-wait-lock))))

  (defn stop [self]
    (with-lock self.--external-synchronization
      (setv self.--exit True)
      (if (and self.--timer (.is_alive self.--timer)) (.cancel self.--timer))
      (.release self.--job-wait-lock)))


  (defn run [self]
    (while (not self.--exit)
      (if (> (len self.--job-list) 0)
          (do
            (with-lock self.--external-synchronization
              (.acquire self.--job-wait-lock)
              (setv self.--timer (Timer
                                   (- (. (.peek self.--job-list) time) (.time time))
                                   (fn [lock] (if (.locked lock) (.release lock)))
                                   [self.--job-wait-lock]))
              (.start self.--timer))
            (with-lock-unchecked-release self.--job-wait-lock
              (setv next-job (.peek self.--job-list))
              (if (and next-job (< next-job.time (.time time)))
                  (try
                    (self.--messaging-function
                      (next-job.function #* next-job.args)
                      next-job.context)
                    (except [e Exception]
                      (print (.format "Error in the Crontab: {}" (repr e)) :file sys.stderr))
                    (finally (.pop self.--job-list))))))
          (with-lock-unchecked-release self.--job-wait-lock
            (.acquire self.--job-wait-lock))))))

(defclass CronBot [PluginBot]
  (defn --init-- [self config]
    (.--init-- (super CronBot self) config)
    (setv self.--tab (CronTab self.--send-message)))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (setv (get kwargs "new_job")
          (fn [time function args] (.add-job (self.--tab (CronJob time function args context)))))
    (.cmd (super CronBot self) command args :context context kwargs)))

(defmain [&rest _]
  (setv tab (CronTab (fn [&rest args] (print (get args 0)))))
  (.start tab)
  (time.sleep 2)

  (.add-job tab (CronJob (+ (.time time) 10) (fn [number] number) [10] '()))
  (.add-job tab (CronJob (+ (.time time) 5) (fn [number] number) [5] '()))
  (while (> (len tab) 0) (time.sleep 2))
  (.stop tab))
