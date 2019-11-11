;; -*- coding: utf-8 -*-
(import [.Terminal [Terminal]])

(defclass ProtocolGlue []
  (defn --init-- [self config]
    (setv
      self.config config
      self.protocol (Terminal self.cmd self.listen config)))

  (defn cmd [self cmd args &kwargs kwargs])

  (defn listen [self message &kwargs kwargs])

  (defn outbound-message [self &optional [message None] [context None] &kwargs kwargs]
    (if (or (= None message) (= None context)) (raise (Exception "missing arguments")))
    (setv parsed-message (if (in "to" kwargs) f"{(get kwargs \"to\")}: {message}" message))
    (self.protocol.outbound-message parsed-message context :kwargs kwargs))

  (defn start [self] (self.protocol.start)))
