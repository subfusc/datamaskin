(import [.PluginBot [PluginBot]])
(import [.cron [CronTab]])

(defclass CronBot [PluginBot]
  "The bot integration against the CronTab allowing plugins to schedule events"

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
    (cond [(and (get kwargs "admin") (= command "reset-cron")) (.clear self.--tab)]
          [(and (get kwargs "admin") (= command "new-cron"))
           (do (try (.stop self.--tab)
                    (except [e Exception]
                      (print (repr e))
                      (.outbound-message self "Cron failed to stop" context
                                         :to context.from-nick)))
               (setv self.--tab (CronTab self.-send-message))
               (.start self.--tab))]
          [True (do (.add-jobs-to-kwarg self context kwargs)
                    (.cmd (super CronBot self) command args :context context #** kwargs))]))

  (defn listen [self message &optional [context '()] &kwargs kwargs]
    (.add-jobs-to-kwarg self context kwargs)
    (.listen (super CronBot self) message :context context #** kwargs))

  (defn stop [self]
    (.stop self.--tab)
    (.stop (super))))

(defmain [&rest _]
  (.start (CronBot {"nick" "Test"
                    "command_prefix" "!"
                    "plugins" ["Useless" "Reminder"]})))
