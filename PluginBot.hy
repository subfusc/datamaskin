(import [XMPPBot [XMPPBot]])
(import [configparser [ConfigParser]])
(import [os.path [isfile]])
(import [Message [Message]])

(defclass PluginBot [XMPPBot]
  (defn --init-- [self config]
    (.--init-- (super PluginBot self) config)
    (setv self.--plugins None)
    (setv self.--functions {})
    (if (in "plugins" config)
        (for [plugin (get config "plugins")]
          (self.--load-plugin plugin))))

  (defn --load-plugin [self plugin]
    (try
      (setv self.--plugins (--import-- f"plugins.{plugin}" (globals) (locals) []))
      (setv config-path f"plugins/{plugin}/plugin.cfg")
      (setv kwargs {})
      (if (isfile config-path)
          (do (setv config (ConfigParser))
              (.read config config-path)
              (setv (get kwargs "config") config)
              (setv (get self.--functions plugin)
                    (eval (read-str f"(plugins.{plugin}.Plugin #** kwargs)")
                          {"plugins" self.--plugins "kwargs" kwargs}))))
      (except [e [Exception]]
        (print (repr e)))))

  (defn --send-message [self messages context]
    (if messages
        (for [message messages]
          (cond [(= (len message 4))
                 (.outbound-message self (get message 3) context :to (get message 2))]
                [(= (len message 3))
                 (.outbound-message self (get message 2) context)]))))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (if context
        (for [plugin (.values self.--functions)]
          (.--send-message
            self
            (.cmd plugin command args context.stream :from_nick context.from-nick)
            context)))
    (.cmd (super PluginBot self) command args :context context #** kwargs)))
