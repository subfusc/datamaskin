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
    (setv self.--run-locked None)
    (setv self.--del-runlocked False)
    (setv self.--lock (Lock)))

  (defn --len-- [self]
    (len self.--tab))

  (defn --add [self job]
    (if (and job (instance? CronJob job))
        (do
          (setv insert-at None)
          (for [[index stored-job] (enumerate self.--tab)]
            (if (> job.next-run stored-job.next-run) (do (setv insert-at index) (break)))
            (else (.append self.--tab job)))
          (if (!= insert-at None) (.insert self.--tab insert-at job)))))

  (defn add [self job]
    (with-lock self.--lock (do (self.--add job) job.id)))

  (defn clear [self]
    (with-lock self.--lock
      (setv self.--tab [])))

  (defn del [self uuid]
    (with-lock self.--lock
      (if (= uuid self.--run-locked.uuid)
          (setv self.--del-runlocked True)
          (do (setv i -1)
              (for [[index stored-job] (enumerate self.--tab)]
                (if (= uuid stored-job.id) (do (setv i index) (break))))
              (if (>= i 0) (del (get self.--tab i)))))))

  (defn at [self key]
    (get self.--tab key))

  (defn --repr-- [self]
    (with-lock self.--lock
      (+ "[" (.join ", " (map (fn [o] (repr o)) self.--tab)) "]")))

  (defn --str-- [self]
    (with-lock self.--lock
      (.join ", " (map (fn [o] f"{(first o)}: {(str (second o))}")
                          (zip (range 0 (len self.--tab)) self.--tab)))))

  (defn peek [self]
    (get self.--tab -1))

  (defn borrow [self]
    (with-lock self.--lock
      (do (if self.--run-locked
              (raise (+ "CronList got a borrow even if there is an object here: "
                        f"{(repr self.--run-locked)}")))
          (if (> (len self.--tab) 0)
              (do (setv self.--run-locked (.pop self.--tab))
                  self.--run-locked)))))

  (defn unborrow [self]
    (with-lock self.--lock
      (do
        (unless self.--run-locked
          (raise (+ "CronList got an unborrow even if there is no object here: "
                    f"{(repr self.--run-locked)}")))
        (unless self.--del-runlocked (self.--add self.--run-locked))
        (setv self.--del-runlocked False)
        (setv self.--run-locked None))))

  (defn continue [self]
    (with-lock self.--lock
      (do (unless self.--run-locked
            (raise (+ "CronList got an unborrow even if there is no object here: "
                      f"{(repr self.--run-locked)}")))
          (if (and self.--run-locked.recurring (not self.--del-runlocked))
              (do (.calc-next-run self.--run-locked)
                  (self.--add self.--run-locked)))
          (setv self.--del-runlocked False)
          (setv self.--run-locked None))))

  (defn pop [self]
    (with-lock self.--lock
      (if (> (len self) 0)
          (.pop self.--tab)))))
