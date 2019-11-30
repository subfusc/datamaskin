;; coding: utf-8
(import [lib.cron.date_calc [*]])
(import [time [time]])

(defn test-is-interval []
  (assert (interval? "P1Y"))
  (assert (interval? "PT1H"))
  (assert (interval? "P3Y7M3W2DT23H55M1S"))
  (assert (not (interval? (time))))
  (assert (not (interval? "P3H")))
  (assert (not (interval? "Foobarium"))))

(defn test-parse-interval []
  (assert (= (parse-interval "P3Y") {"years" 3}))
  (assert (= (parse-interval "PT1H") {"hours" 1}))
  (assert (= (parse-interval "P1Y3WT23M40S")
             {"years" 1 "weeks" 3 "minutes" 23 "seconds" 40}))
  (assert (= (parse-interval "P3Y7M3W2DT23H55M1S")
             {"years" 3 "months" 7 "weeks" 3 "days" 2 "hours" 23 "minutes" 55 "seconds" 1})))

(defn test-leapyears []
  (setv leapyears [1904, 1908, 1912, 1916, 1920, 1924, 1928, 1932, 1936,
                   1940, 1944, 1948, 1952, 1956, 1960, 1964, 1968, 1972,
                   1976, 1980, 1984, 1988, 1992, 1996, 2000, 2004, 2008,
                   2012, 2016, 2020]
        between (range 1900 2021))
  (for [year between]
    (assert (= (in year leapyears) (leapyear? year)))
    (if (in year leapyears)
        (assert (= 366 (add-year year 1)))
        (assert (= 365 (add-year year 1))))))

(defn test-add-month []
  (assert (= 425 (add-month 2019 1 14))))

(defn test-days-in-month []
  (setv year [31 28 31 30 31 30 31 31 30 31 30 31])
  (assert (= 365 (sum year)))
  (for [month (range 1 13)]
    (assert (= (get year (- month 1)) (days-in-month month :year 2019))))
  (assert (= 29 (days-in-month 2 :year 2020))))
