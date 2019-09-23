(import logging)
(import [shutil [copy]])
(import [yaml [load FullLoader]])
(import [XMPPBot [XMPPBot]])
(import [os.path [isfile]])

(defn read-config []
  (unless (isfile "config.yml")
    (do
      (copy "config.yml.sample" "config.yml")
      (print "Please config the user being used for this bot in config.yml")
      (quit)))
  (load (open "config.yml" "r") :Loader FullLoader))


(if (= --name--  "__main__")
    (do
      (setv config (read-config))
      (setv bot (XMPPBot
                  (get config "username")
                  (get config "password")
                  (get config "nick")
                  (get config "rooms")))
      (.basicConfig logging :level logging.DEBUG :format "%(levelname)-8s %(message)s")
      (.register_plugin bot "xep_0030")
      (.register_plugin bot "xep_0045")
      (.register_plugin bot "xep_0199")
      (.connect bot)
      (.process bot :block True)))
