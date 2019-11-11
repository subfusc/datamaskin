;; -*- coding: utf-8 -*-
(import [CronBot [CronTab CronJob]])
(import [random [randrange]])
(import [time [time sleep]])
(import [threading [Lock]])

(defclass SyncList []
  (defn --init-- [self]
    (setv self.list []
          self.lock (Lock)))

  (defn add [self secs]
    (.acquire self.lock)
    (.append self.list secs)
    (.sort self.list)
    (.reverse self.list)
    (.release self.lock))

  (defn next [self]
    (.acquire self.lock)
    (setv e (.pop self.list))
    (.release self.lock)
    e)

  (defn --len-- [self]
    (len self.list)))

(setv *sl* (SyncList))
(setv *correct-order* True)

(defn output-func [output context]
  (print output))

(defn mahfunc [seconds]
  (if (!= (.next *sl*) seconds) (setv *correct-order* False))
  f"Waited for: {seconds}")

(defn randomly-generate-jobs [tab &optional [job-number 10]]
  (for [x (range job-number)]
    (print f"Job number {x}")
    (setv secs (randrange 5 60))
    (.add *sl* secs)
    (.add-job tab (CronJob (+ (time) secs) mahfunc [secs] {}))))

(defmain [&rest _]
  (setv job (CronTab output-func))
  (.start job)
  (randomly-generate-jobs job)
  (sleep 61)
  (.stop job)
  (setv pass (if (and *correct-order* (= 0 (len *sl*) (len job))) "PASS" "FAIL"))
  (print f"Test is {pass}"))
