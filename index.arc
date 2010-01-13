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
    (or pubdate.doc feeddate.doc (time-ago:* 60 60 24 2))) ; hack for corrupted docinfo
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

(init feedinfo* (table))
(defrep update-feeds 1800
  (= feed-list* (tokens:slurp "feeds/All"))
  (= feedinfo* (read-json-table "snapshots/feedinfo"))
  (map feed-keywords feed-list*))
(wait feedinfo*)

(def scan-doc-dir()
  (everyp file (dir "urls") 1000
    (if (and (posmatch ".clean" file)
             (~docinfo*:subst "" ".clean" file))
      (prn file))))



(= userinfo* (table))

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

(def current-station-name(user)
  userinfo*.user!current-station)

(def current-station(user)
  (userinfo*.user!stations current-station-name.user))

(def current-workspace(user)
  current-station.user!workspace)

(proc set-current-station-name(user station)
  (= userinfo*.user!current-station station))

(proc new-station(user sname)
  (or= userinfo*.user!stations.sname (table))
  (let station userinfo*.user!stations.sname
    (or= station!workspace (table))
    (or= station!sorted-docs (slist [salient-recency station!workspace _]))
    (or= station!iter 0)
    (or= station!name sname)
    (add-query user station sname)))

; XXX: refactor
(proc mark-read(user doc outcome)
  (unless userinfo*.user!read.doc
    (ero "marking read " doc)
    (= userinfo*.user!read.doc outcome)
    (withs (s current-station-name.user
            station userinfo*.user!stations.s)
      (push doc station!read-list)
      (delete-sl station!sorted-docs doc)
      (when (iso outcome "read")
        (++ station!iter)
        (prune station)
        (w/stdout (stderr)
          (prn "propagating from " doc " " (len:keys station!workspace))
          (propagate-to-doc user station doc)
          (prn)
          (prn "after prop: " (len:keys station!workspace)))))))

(def most-recent-read(station)
  (car station!read-list))



(persisted feed-keywords-via-doc* (table)
  (proc update-feed-keywords-via-doc(doc)
    (let feed doc-feed.doc
      (or= feed-keywords-via-doc*.feed (table))
      (each kwd doc-keywords.doc
        (pushnew doc feed-keywords-via-doc*.feed.kwd)))))
;?       (update-feed-clusters-by-keyword feed))))

(persisted feed-clusters-by-keyword* (table)
  (proc update-feed-clusters-by-keyword(feed)
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
  (common:map keyword-feeds:canonicalize (tokens keyword)))
(def scan-docs(keyword)
  (common:map keyword-docs:canonicalize (tokens keyword)))

(proc add-query(user station entry)
  (propagate-one user station entry guess-type.entry 'query))

(def guess-type(entry)
  (if (feedinfo* symize.entry)     'feed
      (or doc-keywords*.entry
          doc-keyword-nils*.entry) 'doc
      (headmatch "http" entry)     'url
      (posmatch "//" entry)        'url
                                   'keyword))

(proc propagate-keyword(user station keyword)
  (each feed scan-feeds.keyword
    (propagate-one user station feed 'feed keyword))
  (each doc scan-docs.keyword
    (propagate-one user station doc 'doc keyword)))

(proc propagate-feed(user station feed)
  (each kwd feed-keywords.feed
    (propagate-one user station kwd 'keyword feed))
  (each f (keys feed-affinity*.feed)
    (propagate-one user station f 'feed feed))
  (each doc feed-docs.feed
    (propagate-one user station doc 'doc feed)))

(proc propagate-doc(user station doc)
  (propagate-one user station doc-feed.doc 'feed doc)
  (each kwd doc-keywords.doc
    (propagate-one user station kwd 'keyword doc))
  (each d (keys doc-affinity*.doc)
    (propagate-one user station d 'doc doc)))

(proc propagate-to-doc(user station doc)
  (let feed doc-feed.doc
    (propagate-one user station feed 'feed doc)
    (each d feed-docs.feed
      (propagate-one user station d 'doc feed)))
  (each kwd doc-keywords.doc
    (propagate-one user station kwd 'keyword doc)
    (each d scan-docs.kwd
      (propagate-one user station d 'doc kwd)))
  (each d (keys doc-affinity*.doc)
    (propagate-one user station d 'doc doc)))

(proc propagate-keyword-to-doc(user station keyword)
  (each feed scan-feeds.keyword
    (propagate-one user station feed 'feed keyword)
    (each d feed-docs.feed
      (propagate-one user station d 'doc feed)))
  (each doc scan-docs.keyword
    (propagate-one user station doc 'doc keyword)))

(proc propagate-url(user station url)
  (propagate-keyword user station url))

(proc propagate-entry(user station entry)
  ((eval:symize "propagate-" station!workspace.entry!type) user station entry))

(proc propagate-one(user station entry typ (o prior))
  (when (or (~is typ 'doc) (~read? user entry))
;?     (pr ".")
    (if (is typ 'doc)
      (delete-sl station!sorted-docs entry))
    (or= station!workspace.entry (obj type typ created station!iter))
    (if prior
      (pushnew prior station!workspace.entry!priors))
    (if (is typ 'doc)
      (insert-sl station!sorted-docs entry))))



(def prune(station)
  (let workspace station!workspace
    (each k keys.workspace
      (if (> (- station!iter workspace.k!created)
             (* 3 (len workspace.k!priors)))
        (= workspace.k nil)))))

(def unread-doc(user workspace doc)
  (and (~read? user doc)
       (is 'doc workspace.doc!type)))

(def same-feed(station doc)
  (apply iso (map doc-feed (list doc most-recent-read.station))))

; metric: #priors, break ties with timestamp
(def salient-recency(workspace doc)
  (+ (* 100 (len:priors workspace doc))
;?      (/ doc-timestamp.doc 60 60 24 365)))
     (/ doc-timestamp.doc 10000000)))

(def priors(workspace doc)
  (if workspace.doc
    workspace.doc!priors))

(def pick(user station)
  (best-sl station!sorted-docs [~same-feed station _]))
