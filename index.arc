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
    (or pubdate.doc feeddate.doc (time-ago 432000))) ; (* 60 60 24 2) hack for corrupted docinfo
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



(init userinfo* (table))

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

(def showlist(station)
  (if (no station!showlist)
    rebuild-showlist.station)
  station!showlist)

(def preferred-feed-manual-set(station doc dir)
  (or= station!preferred-feeds (table))
  (with (val (if dir 1 0)
         feed doc-feed.doc)
    (= station!preferred-feeds.feed
       (obj manual val auto val outcome3s 0 outcome1s 0))))

(def preferred-feed?(station doc)
  (aif (and station!preferred-feeds
            (station!preferred-feeds doc-feed.doc))
    it!auto))

(proc set-current-station-name(user station)
  (= userinfo*.user!current-station station))

(proc new-station(user sname)
  (or= userinfo*.user!stations.sname (table))
  (let station userinfo*.user!stations.sname
    (or= station!workspace (table))
    (or= station!sorted-docs
         (slist [salient-recency station!workspace _]))
    (or= station!iter 0)
    (or= station!name sname)
    (add-query user station sname)))

; XXX: refactor
;; Outcome:
;; 4: preferred feed, propagate doc
;; 3: preferred feed after 5 3s, propagate doc
;; 2: do nothing
;; 1:
;;    manually preferred feed: disable prefer after 5 1s
;;    preferred feed: disable after 2 1s
;;    not preferred: unprefer
(proc mark-read(user doc outcome)
  (withs (s current-station-name.user
          station userinfo*.user!stations.s)
    (= outcome int.outcome)
    (unless userinfo*.user!read.doc
      (erp "marking read " doc " " outcome " " type.outcome)
      (= userinfo*.user!read.doc outcome)
        (push doc station!read-list)
        (delete-sl station!sorted-docs doc)
        (pop station!showlist))

    (when (> outcome 2)
      (++ station!iter)
      (prune station)
      (timeout-exec 2
        (propagate-to-doc user station doc)))

    (or= station!preferred-feeds (table))
    (case outcome
      1     (handle-outcome1 station doc)
      3     (handle-outcome3 station doc)
      4     (handle-outcome4 station doc))

    (erp "feedinfo " (station!preferred-feeds doc-feed.doc))))

(proc handle-outcome4(station doc)
  (let feed doc-feed.doc
    (or= station!preferred-feeds.feed (obj manual 0
                                           auto 0
                                           outcome3s 0
                                           outcome1s 0))
    (= station!preferred-feeds.feed!auto 1)))

(proc handle-outcome3(station doc)
  (withs (feed doc-feed.doc
          feedinfo (or= station!preferred-feeds.feed (obj manual 0
                                                          auto 0
                                                          outcome3s 0
                                                          outcome1s 0)))
    (++ feedinfo!outcome3s)
    (if (>= feedinfo!outcome3s 5)
      (preferred-feed-manual-set station doc t))))

(proc handle-outcome1(station doc)
  (withs (feed doc-feed.doc
          feedinfo (or= station!preferred-feeds.feed (obj manual 0
                                                          auto 0
                                                          outcome3s 0
                                                          outcome1s 0)))
    (if (> feedinfo!outcome3s 0)
      (-- feedinfo!outcome3s))

    (when (<= feedinfo!outcome3s 0)
      (++ feedinfo!outcome1s)
      (if (>= feedinfo!outcome1s 5)
        (= feedinfo!manual 0))
      (if (>= feedinfo!outcome1s 7)
        (= feedinfo!auto 0))
      (if (>= feedinfo!outcome1s 8)
        (= feedinfo!auto -1)))))

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
  (each doc keyword-docs*.keyword     ;; Assume already canonicalized
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
  (erp "To propagate:")
  (let feed doc-feed.doc
    (erp (len feed-docs.feed) " docs from feed"))
  (erp (len doc-keywords.doc) " keywords from doc")
  (erp " " (add-tags [len keyword-docs*._] doc-keywords.doc))
  (erp (len-keys doc-affinity*.doc) " docs from doc")
  (let feed doc-feed.doc
    (propagate-one user station feed 'feed doc)
    (each d feed-docs.feed
      (propagate-one user station d 'doc feed)))
  (each kwd doc-keywords.doc
    (propagate-one user station kwd 'keyword doc)
    (each d (firstn 10 keyword-docs*.kwd)
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

(= propagates* 0)
(proc propagate-one(user station entry typ (o prior))
  (when (or (~is typ 'doc) (~read? user entry))
    (++ propagates*)
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
     (/ doc-timestamp.doc 10000000)))

(def priors(workspace doc)
  (if workspace.doc
    workspace.doc!priors))

;; Preferred feeds ds by station. table: feed -> (manual weight (0-n), inferred weight (-1 to 1))
;; Showlist ds: Construct 5 stories at a time
;;   Choose 1 lit doc in worklist
;;   Choose most recent story from upto 3 separate preferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds by affinity, avoiding recent
;;   Fill remainder with most recent story from random feeds, avoiding recent and unpreferred feeds
;;   Fill remainder with most recent story from random unpreferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds
;;
;; Recent = previous batch of 5 and this batch
(def rebuild-showlist(station)
  (push (best-sl station!sorted-docs)
        station!showlist))

(def pick(user station)
  (car showlist.station))
