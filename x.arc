(def current-user()
  0)

(def time-ago(s)
  (- (seconds) s))

(def Set args
  (w/table ans
    (each k args
      (= (ans k) t))))

(def current-user-read(doc)
  (((userinfo* (current-user)) 'read) doc))

(def current-user-mark-read(doc)
  (prn "setting " doc)
  (= (((userinfo* (current-user)) 'read) doc) t))

(def site-docs(site)
  (keep [and (no:current-user-read _)
                 (iso site docinfo*._!site)]
            (keys docinfo*)))

(def randpos(l)
  (l (rand:len l)))

(def random-unread()
  (randpos (rem [current-user-read _] (keys docinfo*))))

(def feed-docs(feed)
  (keep [and (no:current-user-read _)
                 (iso feed docinfo*._!feed)]
            (keys docinfo*)))

(mac init args
  `(unless (bound ',(car args))
     (= ,@args)))

(init doc-generators* ())
(push site-docs doc-generators*)
(push feed-docs doc-generators*)

(def doc-site(doc)
  docinfo*.doc!site)
(def doc-feed(doc)
  docinfo*.doc!feed)

(mac sub-core(f)
  (w/uniq (str rest)
     `(fn(,str . ,rest)
          (let s ,str
            (each (pat repl) (pair ,rest)
                  (= s ($(,f pat s repl))))
            s))))
(= sub (sub-core regexp-replace))
(= gsub (sub-core regexp-replace*))
(def url-doc(url)
  (gsub url
    (r "[^0-9a-zA-Z]") "_"))

(def gen-docs(doc)
  (dedup:flat:accum acc
    (each genfn doc-generators*
      (errsafe:acc genfn.doc)
      (errsafe:acc (genfn:url-doc doc))
      (errsafe:acc (genfn:doc-feed:url-doc doc))
      (errsafe:acc (genfn:doc-site:url-doc doc))
      (errsafe:acc (genfn:doc-keywords:url-doc doc))
    )))

(def doc-keywords(doc)
  docinfo*.doc!keywords)

(def keywords-docs(kwds)
  (rem [current-user-read _] (dedup:flat:map index* kwds)))
