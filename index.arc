(def current-user()
  0)
(persisted userinfo* (table))

(persisted docinfo* (table)
  (def add-to-docinfo(doc attr val)
    (or= docinfo*.doc (table))
    (= docinfo*.doc.attr val))

  (def new?(doc)
    (blank? docinfo*.doc))

  (def url(doc)
    docinfo*.doc!url)
  (def title(doc)
    docinfo*.doc!title)
  (def site(doc)
    docinfo*.doc!site)
  (def feed(doc)
    docinfo*.doc!feed)
  (def feedtitle(doc)
    docinfo*.doc!feedtitle)
  (def timestamp(doc)
    (or pubdate.doc feeddate.doc))
  (def pubdate(doc)
    docinfo*.doc!date)
  (def feeddate(doc)
    docinfo*.doc!feeddate))

(def current-user-read-list()
  ((userinfo*:current-user) 'read-list))

(def current-user-read-history()
  (firstn 10
    (keep [iso "read" (cdr _)] 
          (firstn 20 (current-user-read-list)))))

(def current-user-outcome(doc)
  (aif (find doc (current-user-read-list))
    cdr.it))

(def current-user-read(doc)
  (or= (userinfo*:current-user) (table))
  (or= ((userinfo*:current-user) 'read) (table))
  (((userinfo*:current-user) 'read) doc))

(def current-user-mark-read(doc outcome)
  (or= (userinfo*:current-user) (table))
  (or= ((userinfo*:current-user) 'read) (table))
  (unless (((userinfo*:current-user) 'read) doc)
    (ero doc)
    (push (cons doc outcome) ((userinfo*:current-user) 'read-list))
    (= (((userinfo*:current-user) 'read) doc) t)))



(defreg site-docs(site) doc-generators*
  (keep [and (no:current-user-read _)
             (posmatch site docinfo*._!site)]
        (keys docinfo*)))

(defreg feed-docs(feed) doc-generators*
  (keep [and (no:current-user-read _)
             (posmatch feed docinfo*._!feed)]
        (keys docinfo*)))

(def url-doc(url)
  (gsub url
    (r "[^0-9a-zA-Z]") "_"))

(def gen-docs(doc)
  (dedup:flat:accum acc
    (each genfn doc-generators*
      (errsafe:acc genfn.doc)
      (errsafe:acc (genfn:url-doc doc))
      (errsafe:acc (genfn:feed:url-doc doc))
      (errsafe:acc (genfn:site:url-doc doc))
      (errsafe:acc (genfn:doc-keywords:url-doc doc))
    )))



(defscan insert-metadata "clean" "mdata"
  (= docinfo*.doc metadata.doc))

(def metadata(doc)
  (on-err (fn(ex) (table))
          (fn()
            (w/infile f metadata-file.doc (json-read f)))))

(def metadata-file(doc)
  (+ "urls/" doc ".metadata"))



(dhash doc keyword "m-n"
  (rem "" (errsafe:keywords (+ "urls/" doc ".clean"))))

(defreg keywords-docs(kwds) doc-generators*
  (rem [current-user-read _] (dedup:flat:map (docs-table) kwds)))

(defscan insert-keywords "mdata"
  (doc-keywords doc))



(def contents(doc)
  (slurp (+ "urls/" doc ".clean")))

(def next-doc()
  (randpos:candidates))

(def candidates()
  (gen-docs
    (car:find [pos (cdr _) '("read" "seed")] (current-user-read-list))))
