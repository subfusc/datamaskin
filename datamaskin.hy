(import logging)
(import [shutil [copy]])
(import [yaml [load FullLoader]])
(import [CronBot [CronBot]])
(import [os.path [isfile]])

(defn read-config []
  (unless (isfile "config.yml")
    (do
      (copy "config.yml.sample" "config.yml")
      (print "Please config the user being used for this bot in config.yml")
      (quit)))
  (load (open "config.yml" "r") :Loader FullLoader))


(defmain [&rest _]
  (setv config (read-config))
  (setv bot (CronBot config))
  (.basicConfig logging :level logging.DEBUG :format "%(levelname)-8s %(message)s")
  (.start bot))
