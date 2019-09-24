(defclass Message [object]
  (defn --init-- [self stream -type message nick]
    (setv self.stream stream)
    (setv self.type -type)
    (setv self.message message)
    (setv self.from-nick nick)))
