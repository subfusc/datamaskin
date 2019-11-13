(import [.ProtocolBot [ProtocolBot]])
(import [configparser [ConfigParser]])
(import [os.path [isfile]])

(defclass PluginBot [ProtocolBot]
  (defn --init-- [self config]
    (.--init-- (super) config)
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
              (setv (get kwargs "config") config)))
      (setv (get self.--functions plugin)
            (eval (read-str f"(plugins.{plugin}.Plugin #** kwargs)")
                  {"plugins" self.--plugins "kwargs" kwargs}))
      (except [e [Exception]]
        (print "==================================")
        (print f"Crashed trying to load '{plugin}'")
        (print (repr e)))))

  (defn --unload-plugin [self plugin]
    (del (get self.--functions plugin)))

  (defn -send-message [self messages context]
    (if messages
        (for [message messages]
          (cond [(= (len message 4))
                 (.outbound-message self (get message 3) context :to (get message 2))]
                [(= (len message 3))
                 (.outbound-message self (get message 2) context)]))))

  (defmacro run-plugin-with-error-handling [code]
    `(if context
         (do
           (setv unloads [])
           (for [plugin (.keys self.--functions)]
             (try
               (self.-send-message ~code context)
               (except [e Exception]
                 (.append unloads plugin)
                 (print (.format "Plugin {} raised: {}" plugin (str e))))))
           (for [key unloads] (self.--unload-plugin key)))))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (run-plugin-with-error-handling
      (.cmd (get self.--functions plugin)
            command args context.stream
            :from_nick context.from-nick
            :context context
            #** kwargs))
    (.cmd (super) command args :context context #** kwargs))

  (defn listen [self message &optional [context '()] &kwargs kwargs]
    (run-plugin-with-error-handling
      (.listen (get self.--functions plugin)
               message context.stream
               :from_nick context.from-nick
               :context context
               #** kwargs))
    (.listen (super) message :context context #** kwargs)))
