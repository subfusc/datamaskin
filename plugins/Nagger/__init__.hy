;; -*- coding: utf-8 -*-
(import [time [time]])
(import re)

(defclass Plugin []
  (defn --init-- [self &kwargs _]
    (setv
      self.jobs {}
      self.descriptor-to-secs {"d" 86400 "h" 3600 "t" 3600 "m" 60 "s" 1}
      self.descriptor-to-intv {"d" "D" "h" "H" "t" "H" "m" "M" "s" "S"}
      time-descriptors (+ "(d(ag(er)?|ays?)?|t(imer?)?|h(ours?)?|m(inut(es?|t(er)?))?"
                          "|s(econds?|ekund(er)?)?)")
      self.time-phrase (re.compile (+ "(?P<time>(\s*\d+\s?" time-descriptors
                                      ")+(\s*(and|og)\s+\d+\s?" time-descriptors
                                      ")?)"))
      self.time-split (re.compile (+ "(\d+)\s?" time-descriptors))))

  (defn -time-obj-parse [self time-obj]
    (if (self.time-phrase.match time-obj)
        (do
          (setv days "" sub-days "")
          (for [tm (self.time-split.findall time-obj)]
            (if (= (get tm 1 0) "d")
                (setv days (+ days
                              (get tm 0)
                              (get self.descriptor-to-intv (get tm 1 0))))
                (setv sub-days (+ sub-days
                                  (get tm 0)
                                  (get self.descriptor-to-intv (get tm 1 0))))))
          (+ "P" days "T" sub-days))))

  (defn -split-arg [self args]
    (setv match (self.time-phrase.match args))
    (if match
        (do
          (setv
            interval (cut args (first (.span match)) (second (.span match)))
            nag-obj (.split (.strip (cut args (second (.span match))) " ")))
          [interval (first nag-obj) (.join " " (cut nag-obj 1))])))

  (defn -nag [self channel msg user] [[0 channel user msg]])

  (defn cmd [self command args channel &kwargs kwargs]
    (cond [(= command "nag")
           (do
             (setv sa (self.-split-arg args))
             (if (or (= None sa) (in (second sa) self.jobs))
                 [[0 channel (get kwargs "from_nick") "Allready nagging that"]]
                 (setv (get self.jobs (second sa))
                       ((get kwargs "new_job")
                         (self.-time-obj-parse (first sa))
                        self.-nag
                        [channel
                         (.strip (get sa 2))
                         (second sa)]
                        :disp-name f"Nag[{(second sa)}]"))))]
          [(and (= command "stop-nag") (in args self.jobs))
           (do ((get kwargs "del_job") (get self.jobs args)) (del (get self.jobs args)))]
          [(and (get kwargs "admin") (= command "reset-nag"))
           (do (for [job self.jobs] ((get kwargs "del_job") (get self.jobs job)))
               (setv self.jobs {}))]))


  (defn listen [self msg channel &kwargs kwargs]
    (if (in (get kwargs "from_nick") self.jobs)
        (do
          ((get kwargs "del_job") (get self.jobs (get kwargs "from_nick")))
          (del (get self.jobs (get kwargs "from_nick")))))))


(defmain [&rest _]
  (setv x (Plugin :config {}))
  (print (x.-time-obj-parse "2 dager, 4 timer, 14 minutter og 56 sekunder hva faen")))
