(persisted docinfo* (table)
  (def add-to-docinfo(doc attr val)
    (or= docinfo*.doc (table))
    (= docinfo*.doc.attr val))

  (def new?(doc)
    (blank? docinfo*.doc))

  (def url(doc)
    (errsafe docinfo*.doc!url))
  (def title(doc)
    (errsafe docinfo*.doc!title))
  (def site(doc)
    (errsafe docinfo*.doc!site))
  (def feed(doc)
    (errsafe docinfo*.doc!feed))
  (def feedtitle(doc)
    (errsafe docinfo*.doc!feedtitle))
  (def timestamp(doc)
    (or pubdate.doc feeddate.doc))
  (def pubdate(doc)
    (errsafe docinfo*.doc!date))
  (def feeddate(doc)
    (errsafe docinfo*.doc!feeddate))

  (def contents(doc)
    (slurp (+ "urls/" doc ".clean"))))



(defscan insert-metadata "clean" "mdata"
  (= docinfo*.doc metadata.doc))

(def metadata(doc)
  (read-json-table metadata-file.doc))

(def metadata-file(doc)
  (+ "urls/" doc ".metadata"))

(dhash doc keyword "m-n"
  (rem blank? (errsafe:keywords (+ "urls/" doc ".clean"))))

(defscan insert-keywords "mdata"
  (doc-keywords doc))

(defrep update-feeds 60
  (= feed-list* (tokens:slurp "feeds/All"))
  (= feedinfo* (read-json-table "snapshots/feedinfo")))



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



(def scan-feeds(s)
  (keep [posmatch s _] feed-list*))

(def feed-matches(doc s)
  (keep [posmatch s _] (vals:feedinfo* doc)))

(def scan-feeds(s)
  (keep [feed-matches _ s] keys.feedinfo*))

(def next-doc(user station)
  (randpos keys.docinfo*))
