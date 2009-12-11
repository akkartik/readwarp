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



(defscan insert-metadata "clean" "mdata"
  (= docinfo*.doc metadata.doc))

(def metadata(doc)
  (on-err (fn(ex) (table))
          (fn()
            (w/infile f metadata-file.doc (json-read f)))))

(def metadata-file(doc)
  (+ "urls/" doc ".metadata"))

(defscan insert-keywords "mdata"
  (doc-keywords doc))

(dhash doc keyword "m-n"
  (rem "" (errsafe:keywords (+ "urls/" doc ".clean"))))



(defcmemo cached-downcase(s) 'downcase
  (downcase s))

(defreg site-docs(site) doc-filters*
  [posmatch site (cached-downcase docinfo*._!site)])

(defreg feed-docs(feed) doc-filters*
  [posmatch feed (cached-downcase docinfo*._!feed)])

(def gen-docs(user doc)
  (do1
    (dedup:+
      (keep (apply orf (map [_ doc] doc-filters*))
            (keys docinfo*))
      (keywords-docs user list.doc)
      (keywords-docs user doc-keywords.doc))
    (clear-cmemos 'downcase)))

(def keywords-docs(user kwds)
  (rem [read? user _] (dedup:flat:map (docs-table) kwds)))



(persisted userinfo* (table))

(def new-user(user)
  (or= userinfo*.user (table))
  (or= userinfo*.user!read (table))
  (or= userinfo*.user!stations (table)))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(def stations(user)
  (keys userinfo*.user!stations))

(def current-station(user)
  userinfo*.user!current-station)

(def set-current-station(user station)
  (= userinfo*.user!current-station station))

(def new-station(user station)
  (or= userinfo*.user!stations.station (table)))

(def mark-read(user doc outcome station)
  (unless userinfo*.user!read.doc
    (= userinfo*.user!read.doc outcome)
    (push doc userinfo*.user!stations.station!read-list)))



(def contents(doc)
  (slurp (+ "urls/" doc ".clean")))

(def next-doc(user station)
  (randpos:candidates user station))

(def candidates(user station)
  (gen-docs user
            (car:seed-docs user station)))

(def seed-docs(user station)
  (+ (read-list user station) (list station)))
