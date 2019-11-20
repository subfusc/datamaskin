;; -*- coding: utf-8 -*-
(import [uuid [UUID uuid4]])

(defclass CronJob []
  "An object holding a job for the CronTab with an uuid for reference"

  (defn --init-- [self time function args context &optional [start None] [stop None]]
    (setv
      self.id (uuid4)
      self.time time
      self.function function
      self.args args
      self.context context))

  (defn --repr-- [self]
    f"<job {(repr self.id)}: {self.time}>"))
