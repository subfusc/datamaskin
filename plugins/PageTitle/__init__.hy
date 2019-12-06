;; -*- coding: utf-8 -*-
(import re)
(import [urllib [request parse]])
(import [html.parser [HTMLParser]])

(defclass TitleParser [HTMLParser]
  (defn --init-- [self]
    (setv self.in-title False
          self.title-content "")
    (.--init-- (super)))

  (defn title [self] (if (= self.title-content "") None self.title-content))

  (defn handle-starttag [self tag attrs]
    (if (= tag "title") (setv self.in-title True)))

  (defn handle-endtag [self tag]
    (if (= tag "title") (setv self.in-title False)))

  (defn handle-data [self data]
    (if self.in-title (setv self.title-content (+ self.title-content data)))))

(defclass Plugin []

  (defn --init-- [self &kwargs kws]
    (setv self.find-uri (re.compile "https?://\S+")
          self.blocklist (get kws "config" "blocklist")))

  (defn convert-query [self query]
    (if (< 0 (len query))
        (.join "&"
               (list (map (fn [p] (.join "=" p))
                          (map (fn [p] [(parse.quote (first p)) (parse.quote (second p))])
                               (map (fn [x] (.split x "=")) (.split query "&"))))))))

  (defn convert-path [self path] (parse.quote path))

  (defn is-blocked [self part]
    (any (map (fn [x] (.endswith part x)) self.blocklist)))

  (defn parse-url [self url]
    (setv u (parse.urlsplit url))
    (if (or (.blocked? self (get u 1)) (.blocked? self (get u 2)))
        None
        (parse.urlunsplit [(get u 0) ; scheme
                           (get u 1) ; netloc
                           (self.convert-path (get u 2)) ; path
                           (self.convert-query (get u 3)) ; query
                           (get u 4)]))) ; fragments

  (defn get-page-title [self url-match]
    (try
      (setv urlp (self.parse-url url-match))
      (if urlp
          (do
            (setv
              page (request.urlopen urlp None 2)
              parser (TitleParser))
            (.feed parser (.decode (.read page)))
            (.title parser)))
      (except [e Exception] (print (repr e)) None)))

  (defn listen [self msg channel &kwargs kwargs]
    (setv match (.search self.find-uri msg))
    (if match
        (do
          (setv title (.get-page-title self (.group match 0)))
          (if title [[0 channel (.strip title)]])))))
