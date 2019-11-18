(import logging)
(import [shutil [copy]])
(import [yaml [load FullLoader]])
(import lib) ;; This should be changed at some point
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
  (setv bot (lib.CronBot config))
  (.basicConfig logging :level logging.WARN :format "%(levelname)-8s %(message)s")
  (try
    (.start bot)
    (finally (.stop bot))))
