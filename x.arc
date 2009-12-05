(load "utils.arc")
(load "state.arc")
(unless (bound 'keywords)
  (load "keywords.arc"))

(def current-user()
  0)
(persisted userinfo* (table))

(def time-ago(s)
  (- (seconds) s))

(def Set args
  (w/table ans
    (each k args
      (= (ans k) t))))

(persisted docinfo* (table)
  (def add-to-docinfo(doc attr val)
    (or= docinfo*.doc (table))
    (= docinfo*.doc.attr val))

  (def new?(doc)
    (blank? docinfo*.doc))

  (def doc-url(doc)
    docinfo*.doc!url)
  (def doc-site(doc)
    docinfo*.doc!site)
  (def doc-feed(doc)
    docinfo*.doc!feed)
  (def doc-timestamp(doc)
    (or doc-pubdate.doc doc-feeddate.doc))
  (def doc-pubdate(doc)
    docinfo*.doc!date)
  (def doc-feeddate(doc)
    docinfo*.doc!feeddate))

(def current-user-read(doc)
  (or= (userinfo*:current-user) (table))
  (or= ((userinfo*:current-user) 'read) (table))
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

(init doc-generators* (list site-docs feed-docs keywords-docs))

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

(def insert-metadata()
  (each file (tokens:slurp "crawled")
    (iflet pos (posmatch ".metadata" file)
      (let doc (cut file 0 pos)
        (when (new? doc)
          (prn doc)
          (= docinfo*.doc metadata.file)))))
  nil)

(def metadata(file)
  (on-err (fn(ex) (table))
          (fn()
            (w/infile f (+ "urls/" file) (json-read f)))))

(persisted index* (table))

(def insert-keywords()
  (each doc (keys docinfo*)
    (let file (+ "urls/" doc ".clean")
      (when (file-exists file)
        (prn file)
        (let kwds (errsafe:keywords file)
          (= docinfo*.doc!keywords (rem "" kwds))
          (each kwd kwds
            (unless (empty kwd)
              (push doc index*.kwd))))))))
