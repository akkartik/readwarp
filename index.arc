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
    (push (cons doc outcome) ((userinfo*:current-user) 'read-list))
    (= (((userinfo*:current-user) 'read) doc) t)))



(defcmemo cached-downcase(s) 'downcase
  (downcase s))

(defreg site-docs(site) doc-filters*
  [posmatch site (cached-downcase docinfo*._!site)])

(defreg feed-docs(feed) doc-filters*
  [posmatch feed (cached-downcase docinfo*._!feed)])

(def gen-docs(doc)
  (do1
    (dedup:+
      (keep (apply orf (map [_ doc] doc-filters*)) (keys docinfo*))
      (keywords-docs doc)
      (keywords-docs:doc-keywords doc))
    (clear-cmemos 'downcase)))



(defscan insert-metadata "clean" "mdata"
  (prn doc)
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
  (prn doc)
  (doc-keywords doc))



(def contents(doc)
  (slurp (+ "urls/" doc ".clean")))

(def next-doc()
  (randpos:candidates))

(def candidates()
  (gen-docs
    (car:find [pos (cdr _) '("read" "seed")] (current-user-read-list))))



(= doc-dir* "urls/")

(= s* "/")

(def suffix-path(s d)
  (+ d s* s))
(def path-suffix(p d)
  (cut p (inc:len d))) ; Assume d never ends in '/'

(def each-file-path(d func)
  (unless (file-infinite-loop? d)
    (map (fn(f)
           (if (dir-exists f) (each-file-path f func)
               (file-exists f) (func f)))
      (map [suffix-path _ d] (dir d)))))
(def each-file(d func)
  (each-file-path d [func:path-suffix _ d]))

; Assume dir traversals begin under the code dir.
(def file-infinite-loop?(d)
  (file-exists (+ d s* "utils.arc")))

(= counter 0)
(def read-keywords()
  (prn "Processing keywords " doc-dir*)
  (= counter 0)
  (each-file doc-dir* [add-keywords _])
  nil)

(def add-keywords(doc)
  (when (crawled-url? doc)
    (++ counter)
    (if (is 0 (remainder counter 100))
      (prn counter))
    (doc-keywords rmext.doc)))

(def rmext(s)
  (subst "" ".raw" s))

(def crawled-url?(doc)
  (posmatch ".raw" doc))
