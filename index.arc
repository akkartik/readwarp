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
    (errsafe docinfo*.doc!feeddate)))



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
  (rem blank? (errsafe:keywords (+ "urls/" doc ".clean"))))

;? (defrep update-feeds 60
;?   (= feed-list* (tokens:slurp "feeds/All")))
(def update-feeds()
  (forever
    (= feed-list* (tokens:slurp "feeds/All"))
    (sleep 60)))
(= update-feeds-thread* (new-thread update-feeds))

;? (persisted feed-keywords (table))
;? (defscan update-feed-keywords "index"



; gen-docs:
;   generate candidates using doc-filters* with misc-filters* (currently just keywords-docs)
;   prune by applying doc-constraints*
;   sum feature-scores* for each candidate, return max

;; doc-filters*: doc -> (fn: doc -> bool)
(defreg site-docs(user station site) doc-filters*
  [posmatch site (cached-downcase docinfo*._!site)])

(defreg feed-docs(user station feed) doc-filters*
  [posmatch feed (cached-downcase docinfo*._!feed)])

(defreg doc-matches(user station doc) doc-filters*
  [iso doc _])

(defreg feed-matches(user station doc) doc-filters*
  [iso feed.doc feed._])

(defreg site-matches(user station doc) doc-filters*
  [iso site.doc site._])

(def gen-doc-filters(user station doc)
  (keep (apply orf (map [_ user station doc] doc-filters*))
        keys.docinfo*))

;; misc-filters*: doc -> docs
(defreg keywords-docs(user station doc) misc-filters*
  (rem [read? user _]
       (dedup:flat:map docs*
                       (or doc-keywords.doc list.doc))))

(def gen-misc-filters(user station doc)
  (flat:accum acc
    (each filter misc-filters*
      (acc:filter user station doc))))

(def url-doc(url)
  (gsub url
    (r "[^0-9a-zA-Z]") "_"))

(def docify(s)
  (if (docinfo* s)            s
      (docinfo* url-doc.s)    url-doc.s
                              s))

(def gen-docs(user station)
  (new-station user station)
  (list:max-by score (prune user station (candidates user station))))

(def candidates(user station)
  (do-cmemo 'downcase
    ;; XXX: use more than just the most recent item
    (let doc (docify:car:+ (read-list user station) list.station)
      (rem [read? user _]
        (dedup:+
          (gen-doc-filters user station doc)
          (gen-misc-filters user station doc))))))

(def score(doc)
  0)

(def prune(user station docs)
  (aif (read-list user station)
    (rem [iso (feed:car it) feed._] docs)
    docs))

(= feed-keywords*(table))
(def update-feed-keywords()
  (each doc keys.docinfo*
    (update feed-keywords* feed.doc rcons doc-keywords.doc))
  (nmaptable dedup:flat feed-keywords*))

(def feed-overlap(f1 f2)
  (len:intersect feed-keywords*.f1 feed-keywords*.f2))
(= feed-overlap* (table))
(def update-feed-overlap()
  (let feeds (w/infile f "xfeeds" (tokens:slurp f)) ;keys.feed-keywords*
    (each feed feeds
      (= feed-overlap*.feed (table)))
    (on feed feeds
      (prn index " " feed)
      (each feed2 (rem feed feeds)
        (= feed-overlap*.feed.feed2 (or feed-overlap*.feed2.feed
                                        (feed-overlap feed feed2)))))))



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



(defcmemo cached-downcase(s) 'downcase
  (downcase s))

(def contents(doc)
  (slurp (+ "urls/" doc ".clean")))

(def next-doc(user station)
  (randpos:gen-docs user station))
