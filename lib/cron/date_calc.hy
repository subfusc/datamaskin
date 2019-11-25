;; coding: utf-8
(import [datetime [datetime timedelta]])
(import re)

(setv iso8601-interval (re.compile (+ "^P(?P<years>\d+Y)?(?P<months>\d+M)?"
                                      "(?P<weeks>\d+W)?(?P<days>\d+D)?"
                                      "(T(?P<hours>\d+H)?(?P<minutes>\d+M)?"
                                      "(?P<seconds>\d+S)?)?$"))
      iso8601-date (re.compile (+ "^(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})T"
                                  "(?P<hour>\d{2}):(?P<minute>\d{2}):(?P<second>\d{2})"
                                  "(?P<timezone>[Zz]|([+-]\d{2}:\d{2}))")))

(defn interval? [interval]
  (and (instance? str interval) (.match iso8601-interval interval)))

(defn parse-interval [interval]
  (setv groups (.groupdict (.match iso8601-interval interval))
        parsed {})
  (for [key (.keys groups)]
    (if (get groups key) (setv (get parsed key) (int (cut (get groups key) 0 -1)))))
  parsed)

(defn leapyear? [year]
  (and (= (% year 4) 0)
       (or (!= (% year 100) 0)
           (= (% year 400) 0))))

(defn days-in-month [month &optional [year (. (datetime.now) year)]]
  (cond [(in month [1 3 5 7 8 10 12]) 31]
        [(in month [4 6 9 11]) 30]
        [(= 2 month) (if (leapyear? year) 29 28)]
        [True (raise "Month is out of range")]))

(defn add-year [year number]
  (setv next-year year
        days 0)
  (while (> number 0)
    (setv days (+ days (if (leapyear? next-year) 366 365))
          next-year (inc next-year)
          number (dec number)))
  days)

(defn add-month [year month number]
  (setv days 0
        next-year year
        next-month month)
  (while (> number 0)
    (setv days (+ days (days-in-month next-month :year next-year))
          next-month (if (= next-month 12) 1 (inc next-month))
          next-year (if (= next-month 1) (inc next-year) next-year)
          number (dec number)))
  days)

(defn interval-to-timedelta [interval &optional [start (datetime.now)]]
  (setv
    interval (.copy interval)
    (get interval "days") (+ (add-year start.year (or (.get interval "years") 0))
                             (add-month start.year start.month (or (.get interval "months") 0))
                             (or (.get interval "days") 0)))
  (for [delete ["years" "months"]]
    (if (in delete interval) (del (get interval delete))))
  (timedelta #** interval))
