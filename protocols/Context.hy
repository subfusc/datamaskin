;; -*- coding: utf-8 -*-
(defclass Context []
  (defn --init-- [self message stream from-nick bot-name]
    (setv self.message message
          self.stream stream
          self.from-nick from-nick
          self.name bot-name
          self.self-nick bot-name)))
