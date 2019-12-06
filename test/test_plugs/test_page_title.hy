;; -*- coding: utf-8 -*-
(import [plugins.PageTitle [Plugin]])

(defn test-pagetitle-github []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt "https://github.com" "#channel"))
  (assert (= (len response) 1))
  (assert (= (len (first response)) 3))
  (assert (= (get (first response) 2)
             "The world’s leading software development platform · GitHub")))

(defn test-pagetitle-github-w-noise []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt "foo: Check this https://github.com is so awesome" "#channel"))
  (assert (= (len response) 1))
  (assert (= (len (first response)) 3))
  (assert (= (get (first response) 2)
             "The world’s leading software development platform · GitHub")))

(defn test-pagetitle-malformed []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt "https://hopefullythisisnotapage" "#channel"))
  (assert (not response)))

(defn test-pagetitle-unicode-preencode []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt "https://no.wikipedia.org/wiki/Bokm%C3%A5l" "#channel"))
  (assert (= (get (first response) 2) "Bokmål – Wikipedia")))

(defn test-pagetitle-unicode-unencoded []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt "https://no.wikipedia.org/wiki/Bokmål" "#channel"))
  (assert (= (get (first response) 2) "Bokmål – Wikipedia")))

(defn test-pagetitle-w-params []
  (setv pt (Plugin :config {"blocklist" []})
        response (.listen pt
                          "https://github.com/python/cpython/search?q=foobar&unscoped_q=foobar"
                          "#channel"))
  (assert (= (get (first response) 2) "Search · foobar · GitHub")))

(defn test-blocklist []
  (setv pt (Plugin :config {"blocklist" ["nrk.no" ".png"]})
        response (.listen pt
                          "https://github.com/python/cpython/search?q=foobar&unscoped_q=foobar"
                          "#channel"))
  (assert (= (get (first response) 2) "Search · foobar · GitHub"))
  (setv response (.listen pt
                          "https://www.nrk.no/nyheter/"
                          "#channel"))
  (assert (not response))
  (setv response (.listen pt
                          "https://no.wikipedia.org/static/images/project-logos/nowiki.png"
                          "#channel"))
  (assert (not response)))
