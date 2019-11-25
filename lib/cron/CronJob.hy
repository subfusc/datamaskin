;; -*- coding: utf-8 -*-
(import [uuid [UUID uuid4]])
(import re)
(import [datetime [datetime]])
(import [time [ctime time]])
(import [.date-calc [*]])

(defclass CronJob []
  "An object holding a job for the CronTab with an uuid for reference"

  (defn --init-- [self time-desc function args context
                  &optional [start None] [stop None] [disp-name None] [plugin None]]
    (setv
      ;; Core required variables
      self.id        (uuid4)   ; id for the job
      self.time-desc time-desc ; the time description given
      self.context   context   ; context object given by the protocl
      self.function  function  ; function to be run by the cron
      self.args      args      ; arguments to the function

      ;; Optional modifiers
      self.start     (if start (datetime.fromisoformat start)) ; start time of the job
      self.stop      (if stop  (datetime.fromisoformat stop))  ; stop time of the job
      self.disp-name disp-name                                 ; pretty format for cron-list
      self.plugin    plugin                                    ; plugin it belongs to

      ;; Derived modifiers
      self.recurring (if (interval? self.time-desc) ; decide whether the job is
                         True                       ; recurring or
                         False)                     ; not
      self.next-run None)                             ; the next time this job runs
    (.calc-next-run self))

  (defn calc-next-run [self]
    (setv self.next-run
          (cond [(or (instance? float self.time-desc) (instance? int self.time-desc))
                 self.time-desc]
                [(interval? self.time-desc)
                 (cond [(and (not self.next-run) self.start) (.timestamp self.start)]
                       [(not self.next-run) (time)]
                       [self.next-run (.timestamp
                                        (+ (datetime.fromtimestamp self.next-run)
                                           (interval-to-timedelta
                                             (parse-interval self.time-desc))))])])))

  (defn --str-- [self] (or self.disp-name (ctime self.time-desc)))

  (defn --repr-- [self]
    (+ f"<job:{(repr self.id)} "
       (if self.disp-name f"disp-name: {self.disp-name}, " "")
       (if self.plugin f"plugin: {self.plugin}, " "")
       f"time-desc: {self.time-desc}, "
       (if self.start f"start: {self.start}, " "")
       (if self.stop  f"stop: {self.stop}, " "")
       f"next-run: {(and self.next-run (datetime.fromtimestamp self.next-run))}, "
       f"function: {self.function}>")))
