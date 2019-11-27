;; -*- coding: utf-8 -*-
(import [lib.cron [CronJob]])
(import [datetime [datetime]])
(import [time [time]])

(defn test-create-basic-job []
  (setv
    job-run (+ (time) 30)
    job (CronJob job-run (fn [x] (+ x x )) [5] {} :disp-name "foobar" :plugin "barfoo"))
  (assert (instance? CronJob job))
  (assert (!= job.id None))
  (assert (= job.next-run job-run))
  (assert (= job.context {}))
  (assert (= job.disp-name "foobar"))
  (assert (= job.plugin "barfoo"))
  (assert (= (str job) "foobar"))
  (assert (not job.recurring)))

(defn test-create-recurring-job []
  (setv
    job-run "PT3H4M"
    exp-time (int (time))
    job (CronJob job-run (fn [x] (+ x x)) [5] {} :disp-name "foobar" :plugin "barfoo"))
  (assert (instance? CronJob job))
  (assert (!= job.id None))
  (assert (!= job.next-run None))
  (assert (in (int job.next-run) (range exp-time (+ 2 exp-time))))
  (assert (= job.context {}))
  (assert (= job.disp-name "foobar"))
  (assert (= job.plugin "barfoo"))
  (assert (= (str job) "foobar"))
  (assert job.recurring))

(defn test-calc-next-run-recurring-job []
  (setv
    job-run "PT3H4M"
    exp-time (int (time))
    job (CronJob job-run (fn [x] (+ x x)) [5] {}))
  (assert (in (int job.next-run) (range exp-time (+ exp-time 2))))
  (setv exp-time (+ exp-time 11040))
  (.calc-next-run job)
  (assert (in (int job.next-run) (range exp-time (+ exp-time 2))))
  (setv exp-time (+ exp-time 11040))
  (.calc-next-run job)
  (assert (in (int job.next-run) (range exp-time (+ exp-time 2)))))

(defn test-calc-with-start-date []
  (setv
    job-run "P1DT2S"
    start (+ (int (time)) 36000000)
    job (CronJob job-run (fn [x] (+ x x)) [5] {}
                 :start (.isoformat (.fromtimestamp datetime start))))
  (assert (= (int job.next-run) start))
  (.calc-next-run job)
  (assert (= (int job.next-run) (+ start 86402))))

(defn test-end-date []
  (setv
    stop (+ (int (time)) (* 8 60 60))
    job (CronJob "PT2H"
                 (fn [x] (+ x x)) [5] {}
                 :stop (.isoformat (.fromtimestamp datetime stop))))
  (assert (in (int (.timestamp job.stop)) (range stop (+ stop 2))))
  (.calc-next-run job)
  (assert (in (int (.timestamp job.stop)) (range stop (+ stop 2)))))
