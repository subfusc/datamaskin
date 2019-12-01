;; -*- coding: utf-8 -*-
(import [lib.cron [CronList CronJob]])
(import [uuid [UUID]])
(import [time [time]])
(import [datetime [datetime]])
(import [pytest [raises]])
(import [random [randrange random]])

(defn test-add []
  (setv cl (CronList)
        first (.add cl (CronJob (+ 20 (time)) (fn [x] x) [5] {})))
  (assert (instance? UUID first))
  (assert (= 1 (len cl)))
  (setv sec (.add cl (CronJob (+ 10 (time)) (fn [x] x) [5] {})))
  (assert (instance? UUID sec))
  (assert (!= first sec))
  (assert (= 2 (len cl)))
  (assert (= sec (. (.peek cl) id))))

(defn test-add-invalid []
  (setv cl (CronList))
  (.add cl (CronJob "Invalid timestamp" (fn [x] x) [1] {}))
  (assert (= 0 (len cl))))

(defn test-clear []
  (setv cl (CronList)
        first (.add cl (CronJob (+ 20 (time)) (fn [x] x) [5] {})))
  (assert (= (len cl) 1))
  (assert (= first (. (.peek cl) id)))
  (cl.clear)
  (assert (= (len cl) 0))
  (with [error (raises IndexError)] (.peek cl))
  (assert (in "list index out of range" (repr error))))

(defn test-len []
  (setv cl (CronList))
  (for [x (range 0 20)]
    (.add cl (CronJob (+ (time) (randrange 10 100)) (fn [x] x) [(randrange 1 50)] {})))
  (assert (= 20 (len cl)))
  (for [x (range 0 17)]
    (.add cl (CronJob (+ (time) (randrange 10 100)) (fn [x] x) [(randrange 1 50)] {})))
  (assert (= 37 (len cl))))

(defn test-del []
  (setv cl (CronList)
        last-random None)
  (for [x (range 0 20)]
    (setv last-random
          (.add cl (CronJob (+ (time) (randrange 10 100)) (fn [x] x) [(randrange 1 50)] {}))))
  (assert (= (len cl) 20))
  (.del cl last-random)
  (assert (= (len cl) 19)))

(defn test-at []
  (setv cl (CronList))
  (.add cl (CronJob (+ (time) 10) (fn [x] x) [1] {}))
  (.add cl (CronJob (+ (time) 20) (fn [x] x) [1] {}))
  (.add cl (CronJob (+ (time) 30) (fn [x] x) [1] {}))
  (.add cl (CronJob (+ (time) 40) (fn [x] x) [1] {}))
  (.add cl (CronJob (+ (time) 50) (fn [x] x) [1] {}))
  (.add cl (CronJob (+ (time) 60) (fn [x] x) [1] {}))
  (setv at-3 (.add cl (CronJob (+ (time) 35) (fn [x] x) [1] {})))
  (assert (= (. (.at cl 3) id) at-3)))

(defn test-clear []
  (setv cl (CronList))
  (for [x (range 0 (randrange 5 20))] (.add cl (CronJob (+ (time) x) (fn [y] y) [x] {})))
  (assert (> (len cl) 0))
  (.clear cl)
  (assert (= (len cl) 0)))

(defn test-str []
  (setv cl (CronList))
  (.add cl (CronJob (+ (time) 10) (fn [x] x) [1] {} :disp-name "Foobar"))
  (.add cl (CronJob (+ (time) 5) (fn [x] x) [1] {} :disp-name "Barfoo"))
  (assert (= (str cl) "0: Foobar, 1: Barfoo")))

(defn test-peek []
  (setv cl (CronList)
        job (CronJob (+ (time) 10) (fn [x] x) [1] {} :disp-name "Foobar"))
  (.add cl job)
  (assert (= (.peek cl) job)))

(defn test-pop []
  (setv cl (CronList)
        job (CronJob (+ (time) 5) (fn [x] x) [1] {} :disp-name "Barfoo"))
  (.add cl (CronJob (+ (time) 10) (fn [x] x) [1] {} :disp-name "Foobar"))
  (.add cl job)
  (assert (= (len cl) 2))
  (assert (= job (.pop cl)))
  (assert (= (len cl) 1)))

(defn test-borrow []
  (setv cl (CronList)
        job (CronJob (+ (time) 100) (fn [x] x) [1] {}))
  (.add cl job)
  (assert (= None cl.-CronList--run-locked))
  (assert (= job (.borrow cl)))
  (assert (= job cl.-CronList--run-locked)))

(defn test-unborrow []
  (setv cl (CronList)
        job (CronJob (+ (time) 100) (fn [x] x) [1] {}))
  (.add cl job)
  (.borrow cl)
  (assert (= job cl.-CronList--run-locked))
  (.unborrow cl)
  (assert (= None cl.-CronList--run-locked))
  (assert (= 1 (len cl))))

(defn test-continue []
  (setv cl (CronList)
        job (CronJob (+ (time) 100) (fn [x] x) [1] {}))
  (.add cl job)
  (.borrow cl)
  (assert (= job cl.-CronList--run-locked))
  (.continue cl)
  (assert (= None cl.-CronList--run-locked))
  (assert (= 0 (len cl))))

(defn test-continue-recurring-no-stop []
  (setv cl (CronList)
        job (CronJob "PT10S" (fn [x] x) [1] {}))
  (.add cl job)
  (.borrow cl)
  (assert (= job cl.-CronList--run-locked))
  (.continue cl)
  (assert (= None cl.-CronList--run-locked))
  (assert (= 1 (len cl)))
  (.borrow cl)
  (.continue cl)
  (assert (= 1 (len cl))))

(defn test-borrow-unborrow-allowed-on-empty []
  (setv cl (CronList))
  (assert (= None (.borrow cl)))
  (assert (= None (.unborrow cl)))
  (assert (= None (.continue cl))))

(defn test-stopping-when-job-has-stop []
  (setv cl (CronList)
        job (CronJob "PT10S"
                     (fn [x] x) [1] {}
                     :stop (.isoformat (datetime.fromtimestamp (+ (time) 21)))))
  (.add cl job)
  (assert (= 1 (len cl)))
  (assert (= job (.borrow cl)))
  (.continue cl)
  (assert (= 1 (len cl)))
  (assert (= job (.borrow cl)))
  (.continue cl)
  (assert (= 1 (len cl)))
  (assert (= job (.borrow cl)))
  (.continue cl)
  (assert (= 0 (len cl))))

(defn test-running-timestamps-only []
  (setv cl (CronList))
  (for [x (range 0 40)]
    (.add cl (CronJob (+ (time) (randrange 10 120)) (fn [x] x) [1] {})))
  (setv job None
        timestamp 0
        continues 0)
  (for [x (range 0 20)]
    (setv job (.borrow cl))
    (assert (>= job.next-run timestamp))
    (assert (= job cl.-CronList--run-locked))
    (setv timestamp job.next-run)
    (if (> 0.5 (random))
        (do ;; continue
          (.continue cl)
          (assert (= None cl.-CronList--run-locked))
          (setv continues (inc continues)))
        (do ;; unborrow
          (.unborrow cl)
          (assert (= None cl.-CronList--run-locked)))))
  (assert (= (len cl) (- 40 continues))))
