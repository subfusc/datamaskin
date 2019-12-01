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
    (setv self.find-uri (re.compile "https?://\S+")))

  (defn convert-query [self query]
    (parse.quote query))

  (defn convert-path [self path]
    (parse.quote path))

  (defn parse-url [self url]
    (setv u (parse.urlsplit url))
    (parse.urlunparse [(get u 0) ; scheme
                       (get u 1) ; netloc
                       (self.convert-path (get u 2)) ; path
                       (self.convert-query (get u 3)) ; query
                       (get u 4) ; fragments
                       ""]))

  (defn get-page-title [self url-match]
    (try
      (setv
        page (request.urlopen (self.parse-url url-match) None 2)
        parser (TitleParser))
      (.feed parser (.decode (.read page)))
      (.title parser)
      (except [e Exception] (print (repr e)) None)))

  (defn listen [self msg channel &kwargs kwargs]
    (setv match (.search self.find-uri msg))
    (if match
        (do
          (setv title (.get-page-title self (.group match 0)))
          (if title [[0 channel title]])))))
