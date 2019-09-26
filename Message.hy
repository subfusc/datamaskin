(defclass Message [object]
  (defn --init-- [self stream -type message nick bot-name]
    (setv self.stream stream)
    (setv self.type -type)
    (setv self.message message)
    (setv self.from-nick nick)
    (setv self.self-nick bot-name)))
