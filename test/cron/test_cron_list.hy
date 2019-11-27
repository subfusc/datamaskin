;; -*- coding: utf-8 -*-
(import [lib.cron [CronList CronJob]])
(import [uuid [UUID]])
(import [time [time]])
(import [pytest [raises]])
(import [random [randrange]])

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
