;; -*- coding: utf-8 -*-
(import [plugins.Useless [Plugin]])
(import re)
(setv *config* {"test" {"x" "yes"}})

(defn test-diceroll []
  (setv plugin (Plugin :config *config*)
        response (.cmd plugin "2d6" None "#foobar" :from_nick "foo"))
  (assert (= (len response) 1))
  (assert (= (len (first response)) 4))
  (assert (= (first (first response)) 0))
  (assert (= (second (first response)) "#foobar"))
  (assert (= (get (first response) 2) "foo"))
  (assert (re.match "Sum: \d{1,2}, \[\d, \d\]" (get (first response) 3))))

(defn test-cointoss []
  (setv plugin (Plugin :config *config*)
        response (.cmd plugin "toss" None "#foobar" :from_nick "foo"))
  (assert (= (len response) 1))
  (assert (= (len (first response)) 4))
  (assert (or (= "Head" (get (first response) 3)) (= "Tail" (get (first response) 3)))))
