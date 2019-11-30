;; -*- coding: utf-8 -*-
(import [lib.cron [CronTab CronJob]])
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

(defn test-tab []
  (setv sl (SyncList)
        last-timestamp 0
        tab (CronTab (fn [o c] (assert (instance? int (int o))) (assert (= c {})))))

  (.start tab)
  (for [x (range 10)]
    (setv secs (randrange 1 30))
    (.add sl secs)
    (.add-job tab (CronJob (+ (time) secs)
                           (fn [s] (assert (= (.next sl) s)))
                           [secs] {})))
  (sleep 31)
  (.stop tab))
