;; -*- coding: utf-8 -*-
(import [uuid [UUID uuid4]])
(import re)
(import [datetime [timedelta]])
(import [time [ctime]])

(defclass CronJob []
  "An object holding a job for the CronTab with an uuid for reference"

  [iso8601-interval (re.compile (+ "^P(?P<y>\d+Y)?(?P<mn>\d+M)?(?P<w>\d+W)?(?P<d>\d+D)?"
                                   "(T(?P<h>\d+H)?(?P<m>\d+M)?(?P<s>\d+S)?)?$"))
   days-in {"year" 365 "month" 30 "week" 7}] ;; Middle ground, temp

  (defn --init-- [self time function args context
                  &optional [start None] [stop None] [disp-name None] [plugin None]]
    (setv
      self.id (uuid4)
      self.time time
      self.recurring (if (self.interval? time) True False)
      self.function function
      self.args args
      self.disp-name disp-name
      self.plugin plugin
      self.context context))

  (defn interval? [self interval]
    (and (instance? str interval) (.match self.iso8601-interval interval)))

  (defn interval-to-sec [self]
    (setv interval (.groupdict (.match iso8601-interval self.time)))
    (.total_seconds
      (timedelta :days (+ 1))))

  (defn --str-- [self] (or self.disp-name (ctime self.time)))

  (defn --repr-- [self]
    (+ f"<job:{(repr self.id)} time: {(ctime self.time)}, "
       f"function: {self.function}, context: {(repr self.context)}>")))
