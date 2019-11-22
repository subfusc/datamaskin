(import [uuid [UUID]])

(import [.PluginBot [PluginBot]])
(import [.cron [CronTab CronJob]])

(defclass CronBot [PluginBot]
  "The bot integration against the CronTab allowing plugins to schedule events"

  (defn --init-- [self config]
    (.--init-- (super) config)
    (setv self.--tab (CronTab self.-send-message))
    (.start self.--tab))

  (defn add-jobs-to-kwarg [self context kwargs]
    (setv
      (get kwargs "new_job")
      (fn [time function args &kwargs kwa]
        (.add-job self.--tab (CronJob time function args context #** kwa)))
      (get kwargs "del_job")
      (fn [uuid] (.del-job self.--tab uuid))))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (cond [(and (get kwargs "admin") (= command "cron-reset")) (.clear self.--tab)]
          [(and (get kwargs "admin") (= command "cron-new"))
           (do (try (.stop self.--tab)
                    (except [e Exception]
                      (print (repr e))
                      (.outbound-message self "Cron failed to stop" context
                                         :to context.from-nick)))
               (setv self.--tab (CronTab self.-send-message))
               (.start self.--tab))]
          [(and (get kwargs "admin") (= command "cron-list"))
           (.outbound-message self (str self.--tab) context)]
          [(and (get kwargs "admin") (= command "cron-job"))
           (try (.outbound-message self (repr (.at self.--tab (int args))) context)
                (except [e Exception] (.outbound-message self (str e) context)))]
          [(and (get kwargs "admin") (= command "cron-del"))
                (try
                  (.del-job self.--tab (UUID args))
                  (.outbound-message self f"Deleted job with uuid {args}" context)
                  (except [e Exception] (.outbound-message self (str e) context)))]

          [True (do (.add-jobs-to-kwarg self context kwargs)
                    (.cmd (super CronBot self) command args :context context #** kwargs))]))

  (defn listen [self message &optional [context '()] &kwargs kwargs]
    (.add-jobs-to-kwarg self context kwargs)
    (.listen (super CronBot self) message :context context #** kwargs))

  (defn stop [self]
    (.stop self.--tab)
    (.stop (super))))
