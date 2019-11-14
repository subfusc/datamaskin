;; -*- coding: utf-8 -*-
(import [time [time]])
(import re)

(defclass Plugin []
  (defn --init-- [self]
    (setv
      self.jobs {}
      self.descriptor-to-secs {"d" 86400 "h" 3600 "t" 3600 "m" 60 "s" 1}
      time-descriptors (+ "(d(ag(er)?|ays?)?|t(imer?)?|h(ours?)?|m(inut(es?|t(er)?))?"
                          "|s(econds?|ekund(er)?)?)")
      self.time-phrase (re.compile (+ "(?P<time>(\s*\d+\s?" time-descriptors
                                      ")+(\s*(and|og)\s+\d+\s?" time-descriptors
                                      ")?)"))
      self.time-split (re.compile (+ "(\d+)\s?" time-descriptors))))

  (defn -time-obj-parse [self time-obj]
    (if (self.time-phrase.match time-obj)
        (sum (map (fn [tm]
                    (* (int (get tm 0))
                       (get self.descriptor-to-secs (get tm 1 0))))
                  (self.time-split.findall time-obj)))))

  (defn -split-arg [self args]
    (setv match (self.time-phrase.match args))
    (if match
        (do
          (setv
            interval (cut args (first (.span match)) (second (.span match)))
            nag-obj (.split (.strip (cut args (second (.span match))) " ")))
          [interval (first nag-obj) (.join " " (cut nag-obj 1))])))

  (defn -nag [self channel msg user interval add-job]
    (setv (get self.jobs user)
          (add-job (+ (time) interval) self.-nag [channel msg user interval add-job]))
    [[0 channel user msg]])

  (defn cmd [self command args channel &kwargs kwargs]
    (cond [(= command "nag")
           (do
             (setv sa (self.-split-arg args))
             (unless (or (= None sa) (in (second sa) self.jobs))
               (setv
                 (get self.jobs (second sa)) ((get kwargs "new_job")
                                               (+ (time) (self.-time-obj-parse (first sa)))
                                           self.-nag
                                              [channel
                                               (.strip (get sa 2))
                                               (second sa)
                                               (self.-time-obj-parse (first sa))
                                               (get kwargs "new_job")]))))]
          [(and (= command "stop-nag") (in args self.jobs))
           (do ((get kwargs "del_job") (get self.jobs args))
                   (del (get self.jobs args)))]))


  (defn listen [self msg channel &kwargs kwargs]
    (if (in (get kwargs "from_nick") self.jobs)
        (do
          ((get kwargs "del_job") (get self.jobs (get kwargs "from_nick")))
          (del (get self.jobs (get kwargs "from_nick")))))))


(defmain [&rest _]
  (setv x (Plugin))
  (print (x.-time-obj-parse "2 dager, 4 timer, 14 minutter og 56 sekunder hva faen")))
