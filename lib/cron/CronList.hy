;; -*- coding: utf-8 -*-
(import [threading [Lock]])
(import [.CronJob [CronJob]])

(defmacro with-lock [lock expr]
  `(do
     (.acquire ~lock)
     (try ~expr
          (finally (.release ~lock)))))

(defclass CronList []
  "The list of CronJobs that will be used in the CronTab"

  (defn --init-- [self]
    (setv self.--tab [])
    (setv self.--lock (Lock)))

  (defn --len-- [self]
    (len self.--tab))

  (defn add [self job]
    (with-lock self.--lock
      (if (and job (instance? CronJob job))
          (do
            (setv insert-at None)
            (for [[index stored-job] (enumerate self.--tab)]
              (if (> job.time stored-job.time) (do (setv insert-at index) (break)))
              (else (.append self.--tab job)))
            (if (!= insert-at None) (.insert self.--tab insert-at job))))))

  (defn clear [self]
    (with-lock self.--lock
      (setv self.--tab [])))

  (defn del [self uuid]
    (with-lock self.--lock
      (do
        (setv i -1)
        (for [[index stored-job] (enumerate self.--tab)]
          (if (= uuid stored-job.id) (do (setv i index) (break))))
        (if (>= i 0) (del (get self.--tab i))))))

  (defn --repr-- [self]
    (with-lock self.--lock
      (+ "[" (.join ", " (map (fn [o] (repr o)) self.--tab)) "]")))

  (defn peek [self]
    (get self.--tab -1))

  (defn pop [self]
    (with-lock self.--lock
      (if (> (len self) 0)
          (.pop self.--tab)))))
