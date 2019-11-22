(import [.ProtocolBot [ProtocolBot]])
(import [yaml [load FullLoader]])
(import [os.path [isfile]])
(import sys)
(import traceback)

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
      (setv
        self.--plugins (--import-- f"plugins.{plugin}" (globals) (locals) [])
        config-path f"plugins/{plugin}/plugin.yml"
        kwargs {}
        (get kwargs "config") { #** self.config
                                #** (if (isfile config-path)
                                        (load (open config-path "r") :Loader FullLoader)
                                        {})})
      (setv (get self.--functions plugin)
            (eval (read-str f"(plugins.{plugin}.Plugin #** kwargs)")
                  {"plugins" self.--plugins "kwargs" kwargs}))
      (except [e [Exception]]
        (print "==================================")
        (print f"Crashed trying to load '{plugin}'")
        (traceback.print-exc)
        (print (repr e)))))

  (defn --unload-plugin [self plugin]
    (if (hasattr (get self.--functions plugin) "stop")
        (.stop (get self.--functions plugin)))
    (.--unload-wo-stop self plugin))

  (defn --unload-wo-stop [self plugin]
    (setv mods []
          mprefix (+ "plugins." plugin))
    (for [module sys.modules]
      (if (.startswith module mprefix)
          (.append mods module)))
    (for [module mods] (del (get sys.modules module)))
    (del (get self.--functions plugin)))

  (defn -send-message [self messages context]
    (if messages
        (for [message messages]
          (cond [(= (len message) 4)
                 (.outbound-message self (get message 3) context :to (get message 2))]
                [(= (len message) 3)
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
                 (traceback.print-exc)
                 (print (.format "Plugin {} raised: {}" plugin (str e))))))
           (for [key unloads] (self.--unload-plugin key)))))

  (defn cmd [self command args &optional [context '()] &kwargs kwargs]
    (if (and (in "admin" kwargs) (get kwargs "admin"))
        (try
          (cond [(= command "load") (self.--load-plugin args)]
                [(= command "force-unload") (self.--unload-wo-stop args)]
                [(= command "unload") (self.--unload-plugin args)]
                [(= command "reload") (do
                                        (self.--unload-plugin args)
                                        (self.--load-plugin args))]
                [(= command "loaded") (.outbound-message
                                        self
                                        :message (.format "Loaded: {}"
                                                          (.join ", " (.keys self.--functions)))
                                        :context context)])
          (if (in command ["load" "unload" "reload" "forceunload"])
              (.outbound-message self
                                 :message f"{command} «{args}»: [ OK ]"
                                 :context context))
          (except [e Exception]
            (.outbound-message self
                               :message f"{command} «{args}»: [ FAILED ] "
                               :context context))))

    (run-plugin-with-error-handling
      (if (hasattr (get self.--functions plugin) "cmd")
          (.cmd (get self.--functions plugin)
                command args context.stream
                :from_nick context.from-nick
                :context context
                #** kwargs)))
    (.cmd (super) command args :context context #** kwargs))

  (defn listen [self message &optional [context '()] &kwargs kwargs]
    (run-plugin-with-error-handling
      (if (hasattr (get self.--functions plugin) "listen")
          (.listen (get self.--functions plugin)
                   message context.stream
                   :from_nick context.from-nick
                   :context context
                   #** kwargs)))
    (.listen (super) message :context context #** kwargs))

  (defn stop [self]
    (for [plugin (.keys self.--functions)]
      (try
        (if (hasattr (get self.--functions plugin) "stop")
            (.stop (get self.--functions plugin)))
        (except [e Exception]
          (traceback.print-exc)
          (print (repr e))
          (print f"Exception stopping plugin: {plugin}"))))
    (.stop (super))))
