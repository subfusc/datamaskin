;; -*- coding: utf-8 -*-
(import re)
(import [urllib [request]])

(defclass Plugin []

  (defn --init-- [self &kwargs kws])

  (defn convert-domain [self domain])

  (defn convert-label [self label])

  (defn convert-query [self query])

  (defn convert-path [self path])

  (with-decorator classmethod
    (defn to-ascii [cls uni-str] ;; TODO
      (setv us (.encode uni-str "UTF-8"))
      ))

  (with-decorator classmethod
    (defn unicode-to-hex [cls uni-str]
      (.join "" (map
                  (fn [hx] (if (> hx 127) (% "%%%x" hx) (chr hx)))
                  (.encode uni-str "UTF-8"))))))
