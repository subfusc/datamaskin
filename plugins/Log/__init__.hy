;; -*- coding: utf-8 -*-
(import datetime)
(import [os [path makedirs]])

(defclass Plugin []
  "The Log plugin should log everything running through this"

  [cmd-format "{date} {channel} {from_name} {cmdchar}{cmd} {args}\n"
   listen-format "{date} {channel} {from_name} {message}\n"]

  (defn --init-- [self &kwargs kws]
    (setv
      self.name (get kws "config" "nick")
      self.cmdchar (get kws "config" "command_prefix")
      self.directory (or (.get (.get kws "config") "log_dir") "data/logs/")
      self.log-buffer-size (or (.get (.get kws "config") "log_buffer_size") 1)
      self.files {})
    (unless (path.exists self.directory) (makedirs self.directory)))

  (defn log [self line channel]
    (unless (in channel self.files)
      (setv
        (get self.files channel) (open (+ self.directory channel ".log")
                                       "a"
                                       :buffering self.log_buffer_size)))
    (.write (get self.files channel) line)
    None)

  (defn cmd [self cmd args channel &kwargs kws]
    (.log self
          (.format self.cmd-format
                   :date (.isoformat (datetime.datetime.now))
                   :channel channel
                   :from-name (get kws "from_nick")
                   :cmdchar self.cmdchar
                   :cmd cmd
                   :args args)
          channel))

  (defn listen [self msg channel &kwargs kws]
    (.log self
          (.format self.listen-format
                   :date (.isoformat (datetime.datetime.now))
                   :channel channel
                   :from-name (get kws "from_nick")
                   :message msg)
          channel))

  (defn stop [self]
    (for [fd (.values self.files)] (.close fd))))
