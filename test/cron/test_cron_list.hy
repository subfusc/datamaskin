;; -*- coding: utf-8 -*-
(import [lib.cron [CronList CronJob]])
(import [uuid [UUID]])
(import [time [time]])
(import [pytest [raises]])

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
