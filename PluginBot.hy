(import [XMPPBot [XMPPBot]])
(import [ConfigParser [ConfigParser]])
(import [os.path [isfile]])

(defclass PluginBot [XMPPBot]
  (defn --init-- [self config]
    (setv self.--plugins None)
    (if (in "plugins" test)
        (for [plugin (get config "plugins")]
          (self.--load-plugin plugin))))

  (defn --load-plugin [self plugin]
    (try
      (setv self.--plugins --import--((format "plugins.%s" plugin) (globals) (locals) [] -1))
      (setv config-path (format "plugins/%s/plugin.cfg" plugin))
      (setv kwargs {})
      (if (isfile config-path)
          (do (setv config (ConfigParser))
              (.readfp config config-path)
              (setv (get kwargs "config") config)
              (eval (format "(plugins.%s.Plugin #** kwargs)" plugin)
                    {"plugins" self.--plugins "kwargs" kwargs})))
      (except [e [Exception]]
        (print (repr e))))))
