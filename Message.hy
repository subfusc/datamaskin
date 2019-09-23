(defclass Message [object]
  (defn --init-- [self stream _type message nick]
    (setv
      self.stream stream
      self.type _type
      self.message message
      self.from-nick nick))

  (defn nick [self]
    self.from-nick))
