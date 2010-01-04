(persisted docinfo* (table)
  (def add-to-docinfo(doc attr val)
    (or= docinfo*.doc (table))
    (= docinfo*.doc.attr val))

  (def new?(doc)
    (blank? docinfo*.doc))

  (def doc-url(doc)
    (errsafe docinfo*.doc!url))
  (def doc-title(doc)
    (errsafe docinfo*.doc!title))
  (def doc-site(doc)
    (errsafe docinfo*.doc!site))
  (rhash doc feed "n-1"
    (errsafe docinfo*.doc!feed)
    rconsuniq)
  (def doc-feedtitle(doc)
    (errsafe docinfo*.doc!feedtitle))
  (def doc-timestamp(doc)
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
  (doc-feed doc)
  (doc-keywords doc))

(dhash feed keyword "m-n"
  (map canonicalize (flat:map tokens:html-strip (vals:feedinfo* symize.feed))))

(defrep update-feeds 1800
  (= feed-list* (tokens:slurp "feeds/All"))
  (= feedinfo* (read-json-table "snapshots/feedinfo"))
  (map feed-keywords feed-list*))
(wait feedinfo*)

(def scan-doc-dir()
  (everyp file (dir "urls") 1000
    (if (and (posmatch ".clean" file)
             (no:docinfo*:subst "" ".clean" file))
      (prn file))))



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



(def scan-feeds(query)
  (common:map keyword-feeds (tokens query)))

(def next-doc(user station)
  (car:sort-by doc-timestamp (keep [not:read? user _]
                                   (flat:map [feed-docs _]
                                             scan-feeds.station))))
