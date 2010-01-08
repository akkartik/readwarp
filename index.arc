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
  (doc-keywords doc)
  (update-feed-keywords-via-doc doc))

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

(def current-workspace(user)
  ((userinfo*.user!stations current-station.user) 'workspace))

(def set-current-station(user station)
  (= userinfo*.user!current-station station))

(def new-station(user station)
  (or= userinfo*.user!stations.station (table))
  (add-keyword user station station))

(def mark-read(user doc outcome)
  (unless userinfo*.user!read.doc
    (ero "marking read " doc)
    (= userinfo*.user!read.doc outcome)
    (withs (s current-station.user
            station userinfo*.user!stations.s)
      (push doc station!read-list)
      (when (iso outcome "read")
        (ero "propagating from " doc " " (len:keys station!workspace))
        (propagate-doc station!workspace doc)
        (ero "after prop: " (len:keys station!workspace))))))



(persisted feed-keywords-via-doc* (table)
  (def update-feed-keywords-via-doc(doc)
    (let feed doc-feed.doc
      (or= feed-keywords-via-doc*.feed (table))
      (each kwd doc-keywords.doc
        (pushnew doc feed-keywords-via-doc*.feed.kwd)))))
;?       (update-feed-clusters-by-keyword feed))))

(persisted feed-clusters-by-keyword* (table)
  (def update-feed-clusters-by-keyword(feed)
    (each k (keys feed-keywords-via-doc*.feed)
      (if (>= (* 2 (len feed-keywords-via-doc*.feed.k))
              (len feed-docs.feed))
        (pushnew feed feed-clusters-by-keyword*.k)
        (pull feed feed-clusters-by-keyword*.k)))))

(persisted feed-affinity* (table)
  (defrep update-feed-affinity 3600
    (= feed-affinity*
       (normalized-affinity-table feed-clusters-by-keyword*))))

(persisted doc-affinity* (table)
  (defrep update-doc-affinity 3600
    (= doc-affinity*
       (normalized-affinity-table keyword-docs*))))



(def scan-feeds(keyword)
  (common:map keyword-feeds (tokens keyword)))
(def scan-docs(keyword)
  (common:map keyword-docs (tokens keyword)))

(def add-keyword(user station keyword)
  (or= userinfo*.user!stations.station!workspace (table))
  (let workspace userinfo*.user!stations.station!workspace
    (add-query workspace keyword)
    (propagate-keyword workspace keyword)))

(def add-query(workspace keyword)
  (propagate-one workspace keyword 'keyword 'query))

(proc propagate(user station)
  (let workspace userinfo*.user!stations.station!workspace
    (each entry keys.workspace
      (prn entry)
      (case workspace.entry!type
        keyword   (propagate-keyword workspace entry)
        feed      (propagate-feed workspace entry)
        doc       (propagate-doc workspace entry)))))

(def propagate-keyword(workspace keyword)
  (each feed scan-feeds.keyword
    (propagate-one workspace feed 'feed keyword))
  (each doc scan-docs.keyword
    (propagate-one workspace doc 'doc keyword)))

(def propagate-feed(workspace feed)
  (each kwd feed-keywords.feed
    (propagate-one workspace kwd 'keyword feed))
  (each f (keys feed-affinity*.feed)
    (propagate-one workspace f 'feed feed))
  (each doc feed-docs.feed
    (propagate-one workspace doc 'doc feed)))

(def propagate-doc(workspace doc)
  (ero:len doc-keywords.doc)
  (propagate-one workspace doc-feed.doc 'feed doc)
  (each kwd doc-keywords.doc
    (propagate-one workspace kwd 'keyword doc))
  (each d (keys doc-affinity*.doc)
    (propagate-one workspace d 'doc doc)))

(def propagate-1iter(workspace doc)
  ((eval:symize "propagate-" workspace.doc!type) workspace doc))

(def propagate-one(workspace entry typ (o prior))
  (or= workspace.entry (obj type typ))
  (if prior
    (pushnew prior workspace.entry!priors)))



;; XXX: copy of propagate
(proc reinforce(user station)
  (let workspace userinfo*.user!stations.station!workspace
    (each entry keys.workspace
      (prn entry)
      (case workspace.entry!type
        keyword   (reinforce-keyword workspace entry)
        feed      (reinforce-feed workspace entry)
        doc       (reinforce-doc workspace entry)))))

(def reinforce-keyword(workspace keyword)
  (each feed scan-feeds.keyword
    (reinforce-one workspace feed 'feed keyword))
  (each doc scan-docs.keyword
    (reinforce-one workspace doc 'doc keyword)))

(def reinforce-feed(workspace feed)
  (each kwd feed-keywords.feed
    (reinforce-one workspace kwd 'keyword feed))
  (each f (keys feed-affinity*.feed)
    (reinforce-one workspace f 'feed feed))
  (each doc feed-docs.feed
    (reinforce-one workspace doc 'doc feed)))

(def reinforce-doc(workspace doc)
  (reinforce-one workspace doc-feed.doc 'feed doc)
  (each kwd doc-keywords.doc
    (reinforce-one workspace kwd 'keyword doc))
  (each d (keys doc-affinity*.doc)
    (reinforce-one workspace d 'doc doc)))

(def reinforce-one(workspace entry typ prior)
  (iflet item workspace.entry
    (pushnew prior item!priors)))



(def unread-doc(user doc)
  (and (not:read? user doc)
       (is 'doc workspace.doc!type)))

(def salient-recency(workspace doc)
  (+ (* 1000 (len workspace.doc!priors))
     doc-timestamp.doc))

(def pick(user workspace)
  (car:sort-by [salient-recency workspace _]
               (keep unread-doc keys.workspace)))



(def next-doc(user station)
  (pick user current-workspace.user))
