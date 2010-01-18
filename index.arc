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

(dhash doc keyword "m-n"
  (rem blank? (errsafe:keywords (+ "urls/" doc ".clean"))))

(init feedinfo* (table))
(dhash feed keyword "m-n"
  (map canonicalize (flat:map tokens:html-strip (vals:feedinfo* symize.feed))))

(init feed-group* (table))
(init group-feeds* (table))
(proc read-group(f)
  (each feed (tokens:slurp:+ "feeds/" f)
    (= feed-group*.feed f)
    (push feed group-feeds*.f)))



(persisted feed-keywords-via-doc* (table)
  (proc update-feed-keywords-via-doc(doc)
    (let feed doc-feed.doc
      (or= feed-keywords-via-doc*.feed (table))
      (each kwd doc-keywords.doc
        (pushnew doc feed-keywords-via-doc*.feed.kwd))
      (update-feed-clusters-by-keyword feed))))

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



(defscan insert-metadata "clean" "mdata"
  (= docinfo*.doc metadata.doc))

(def metadata(doc)
  (read-json-table metadata-file.doc))

(def metadata-file(doc)
  (+ "urls/" doc ".metadata"))

(defscan insert-keywords "mdata"
  (doc-feed doc)
  (doc-keywords doc)
  (update-feed-keywords-via-doc doc))

(defrep update-feeds 1800
  (= feed-list* (tokens:slurp "feeds/All"))
  (map read-group '("Mainstream" "Economics" "Sports"
                    "Programming" "Technology" "Venture"))
  (= feedinfo*
     (if (file-exists "snapshots/feedinfo")
           (read-json-table "snapshots/feedinfo")
         (file-exists "snapshots/feedinfo.intermediate")
           (read-json-table "snapshots/feedinfo.intermediate")
         (file-exists "snapshots/feedinfo.orig") ; temporary
           (w/infile f "snapshots/feedinfo.orig"
              (read-nested-table f))))
  (map feed-keywords feed-list*))
(wait feedinfo*)

(def scan-doc-dir()
  (everyp file (dir "urls") 1000
    (if (and (posmatch ".clean" file)
             (~docinfo*:subst "" ".clean" file))
      (prn file))))



(prn "Rest of index.arc")
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

(def unpreferred?(feedinfo)
  (is feedinfo!auto -1))

(def preferred?(feedinfo)
  (and feedinfo!auto (~is feedinfo!auto -1)))

; Invariant: manual => auto
(def preferred-feed-manual-set(station doc dir)
  (or= station!preferred-feeds (table))
  (= (station!preferred-feeds doc-feed.doc)
     (obj manual  dir
          auto    (if dir doc))))

(def preferred-feed?(station doc)
  (aif (and station!preferred-feeds
            (station!preferred-feeds doc-feed.doc))
    preferred?.it))

(proc set-current-station-name(user station)
  (= userinfo*.user!current-station station))

(proc new-station(user sname)
  (erp "new-station")
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
;?       (erp "marking read " doc " " outcome)
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
    (let feed doc-feed.doc
      (case outcome
        1     (handle-outcome1 station feed doc)
        3     (handle-outcome3 station feed doc)
        4     (handle-outcome4 station feed doc))

;?       (erp "feedinfo " (station!preferred-feeds doc-feed.doc))
)))

(proc handle-outcome4(station feed doc)
  (let feedinfo (or= station!preferred-feeds.feed (table))
    (= feedinfo!auto doc)))

(proc handle-outcome3(station feed doc)
  (let feedinfo (or= station!preferred-feeds.feed (table))
    (push doc feedinfo!outcome3s)
    (if (>= (len feedinfo!outcome3s) 5)
      (= feedinfo!auto doc))))

(proc handle-outcome1(station feed doc)
  (let feedinfo (or= station!preferred-feeds.feed (table))
    (if feedinfo!outcome3s
      (pop feedinfo!outcome3s)
      (let l (len (pushnew doc feedinfo!outcome1s))
        (if (>= l 6)      (= feedinfo!auto -1)
            (>= l 5)      (wipe feedinfo!auto)
            (>= l 3)      (wipe feedinfo!manual))))))



(def scan-feeds(keyword)
  (common:map keyword-feeds:canonicalize (tokens keyword)))
(def scan-docs(keyword)
  (common:map keyword-docs:canonicalize (tokens keyword)))

(proc add-query(user station entry)
  (propagate-one user station entry guess-type.entry 'query)
  (or= station!feeds feed-group-for.entry))

(def feed-group-for(query)
  (let freq (table)
    (each g (map feed-group* scan-feeds.query)
      (or= freq.g 0)
      (++ freq.g))
    (let max first-key.freq
      (each (k v) freq
        (if (> v freq.max)
          (= max k)))
      (erp "Group: " max)
      group-feeds*.max)))

(def guess-type(entry)
  (if entry
    (if (feedinfo* symize.entry)     'feed
        (or doc-keywords*.entry
            doc-keyword-nils*.entry) 'doc
        (headmatch "http" entry)     'url
        (posmatch "//" entry)        'url
                                     'keyword)))

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
  (erp "propagate-keyword-to-doc")
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



(def showlist(user station)
  (when (no station!showlist)
    (rebuild-showlist user station))
  station!showlist)

;; Pick 5 stories at a time
;;   Choose 1 lit doc in worklist
;;   Choose most recent story from upto 3 separate preferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds by affinity, avoiding recent
;;   Fill remainder with most recent story from random feeds, avoiding recent and unpreferred feeds
;;   Fill remainder with most recent story from random unpreferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds
(proc rebuild-showlist(user station)
  (erp "scanning preferred feeds: " station!showlist)
  (choose-from-preferred user station 3)
  (erp "scanning feeds by affinity: " station!showlist)
  (fill-by-affinity user station)
  (erp "scanning feeds by group: " station!showlist)
  (fill-by-group user station)
  (erp "scanning random feeds: " station!showlist)
  (fill-random user station)
  (erp "scanning unpreferred feeds: " station!showlist)
  (fill-random-unpreferred user station)
  (erp "rebuild-showlist. Previous iter: " station!last-showlist)
  (choose-lit-doc station)
  (erp "done. candidates: " station!showlist)
  (= station!last-showlist station!showlist)
  (erp "done rebuild-showlist"))

(proc choose-lit-doc(station)
  (push (doc-feed:best-sl station!sorted-docs [~recently-shown-feed? station _])
        station!showlist))

(mac w/unread-avoiding-recent(user station l . body)
  `(let candidates ,l
    (nkeep [and (~recently-shown? ,station _)
                (most-recent-unread ,user _)]
           candidates)
    ,@body))

(proc choose-from-preferred(user station n)
  (w/unread-avoiding-recent user station (keep [preferred? station!preferred-feeds._]
                                               (keys station!preferred-feeds))
    (repeat n
      (whenlet feed randpos.candidates
        (erp "preferred: " feed)
        (push feed station!showlist)
        (pull feed candidates)))))

(proc fill-by-affinity(user station)
  (w/unread-avoiding-recent user station (keep [is 'feed guess-type._]
                                               (keys station!workspace))
    (while (and candidates
                (< (len station!showlist) 5))
      (let feed randpos.candidates
        (pushnew feed station!showlist)
        (pull feed candidates)))))

(proc fill-by-group(user station)
  (w/unread-avoiding-recent user station station!feeds
    (while (and candidates
                (< (len station!showlist) 5))
      (let feed randpos.candidates
        (pushnew feed station!showlist)
        (pull feed candidates)))))

(proc fill-random(user station)
  (w/unread-avoiding-recent user station feed-list*
    (while (and candidates
                (< (len station!showlist) 5))
      (let feed randpos.candidates
        (unless (and station!preferred-feeds
                     station!preferred-feeds.feed
                     station!preferred-feeds.feed!auto)
          (pushnew feed station!showlist))
        (pull feed candidates)))))

(proc fill-random-unpreferred(user station)
  (w/unread-avoiding-recent user station feed-list*
    (while (and candidates
                (< (len station!showlist) 5))
      (let feed randpos.candidates
        (if (and station!preferred-feeds
                 station!preferred-feeds.feed
                 (unpreferred? station!preferred-feeds.feed))
          (pushnew feed station!showlist))
        (pull feed candidates)))))

(def recently-shown?(station feed)
  (or (pos feed station!last-showlist)
      (pos feed station!showlist)))
(def recently-shown-feed?(station doc)
  (recently-shown? station doc-feed.doc))

(def pick(user station)
  (ret ans (car (showlist user station))
    (if (pos guess-type.ans '(feed url))
      (zap [most-recent-unread user _] ans))))
      ; XXX: nothing unread left? (only dup feeds)

(def most-recent-unread(user feed)
  (most doc-timestamp (rem [read? user _] feed-docs.feed)))



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

(def most-recent-read(station)
  (car station!read-list))

; metric: #priors, break ties with timestamp
(def salient-recency(workspace doc)
  (+ (* 100 (len:priors workspace doc))
     (/ doc-timestamp.doc 10000000)))

(def priors(workspace doc)
  (if workspace.doc
    workspace.doc!priors))

(prn "Done loading index.arc")
