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
    (errsafe:do
      (or= docinfo*.doc metadata.doc)
      docinfo*.doc!feed)
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

(init feedinfo* (table))
(proc update-feedinfo()
  (= feedinfo*
     (if (file-exists "snapshots/feedinfo")
           (read-json-table "snapshots/feedinfo")
         (file-exists "snapshots/feedinfo.intermediate")
           (read-json-table "snapshots/feedinfo.intermediate")
         (file-exists "snapshots/feedinfo.orig") ; temporary
           (w/infile f "snapshots/feedinfo.orig"
              (read-nested-table f)))))

(dhash feed keyword "m-n"
  (map canonicalize
       (cons feed
             (flat:map split-urls
                       (flat:map tokens:html-strip
                                 (vals:feedinfo* symize.feed))))))

(proc update-feed-keywords()
  (= feed-keywords* (table) keyword-feeds* (table) feed-keyword-nils* (table))
  (everyp feed feed-list* 100
    (feed-keywords feed)))

(init feed-group* (table))
(init group-feeds* (table))
(proc read-group(f)
  (each feed (tokens:slurp:+ "feeds/" f)
    (= feed-group*.feed f)
    (push feed group-feeds*.f)))

(= feed-groups* '(
        "Art"
        "BayArea"
        "Books"
        "Comics"
        "Cricket"
        "Design"
        "Economics"
        "Food"
        "Germany"
        "India"
        "Japan"
        "Law"
        "Magazine"
        "Movies"
        "Music"
        "News"
        "NYC"
        "Politics"
        "Programming"
        "Science"
        "Sports"
        "Technology"
        "Travel"
        "Venture"
      ))

(proc update-feed-groups()
  (each group feed-groups*
    prn.group
    (read-group group)))

(defrep update-feeds 3600
  (system "date")
  (prn "updating feed-list*")
  (= feed-list* (tokens:slurp "feeds/All"))
  (prn "updating feed-group*")
  (update-feed-groups)
  (prn "updating feedinfo*")
  (update-feedinfo)
  (prn "updating scan-feeds")
  (update-feed-keywords))
(wait update-feeds-init*)



(def metadata(doc)
  (read-json-table metadata-file.doc))

(def metadata-file(doc)
  (+ "urls/" doc ".metadata"))

(defscan index-doc "clean"
  (doc-feed doc))



(prn "Rest of index.arc")
(init userinfo* (table))

(def new-user(user)
  (inittab userinfo*.user
           'read (table) 'stations (table)))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(def stations(user)
  (keys userinfo*.user!stations))

(def unpreferred?(feedinfo)
  (is feedinfo!auto -1))

(def preferred?(feedinfo)
  (and feedinfo!auto (~is feedinfo!auto -1)))

; Invariant: manual => auto
(def preferred-feed-manual-set(station doc dir)
  (inittab station!preferred-feeds
           doc-feed.doc
            (obj manual dir
                 auto   (if dir doc))))

(def preferred-feed?(station doc)
  (aif (and station!preferred-feeds
            (station!preferred-feeds doc-feed.doc))
    preferred?.it))

(proc new-station(user sname)
  (erp "new-station: " sname)
  (when (no userinfo*.user!stations.sname)
    (= userinfo*.user!stations.sname (table))
    (let station userinfo*.user!stations.sname
      (= station!name sname)
      (= station!showlist (keep [most-recent-unread user _] scan-feeds.sname))
      (= station!feeds feed-group-for.sname))))

;; Outcome:
;; 4: preferred feed, propagate doc
;; 3: preferred feed after 5 3s, propagate doc
;; 2: do nothing
;; 1:
;;    manually preferred feed: disable prefer after 5 1s
;;    preferred feed: disable after 2 1s
;;    not preferred: unprefer
(proc mark-read(user sname doc outcome)
  (let station userinfo*.user!stations.sname
    (= outcome int.outcome)
    (unless userinfo*.user!read.doc
      (= userinfo*.user!read.doc outcome)
        (push doc station!read-list)
        (pop station!showlist))

    (let feed doc-feed.doc
      (inittab station!preferred-feeds
               feed (table))
      (case outcome
        1     (handle-outcome1 station!preferred-feeds.feed doc)
        3     (handle-outcome3 station!preferred-feeds.feed doc)
        4     (handle-outcome4 station!preferred-feeds.feed doc))
)))

(proc handle-outcome4(feedinfo doc)
  (= feedinfo!auto doc))

(proc handle-outcome3(feedinfo doc)
  (push doc feedinfo!outcome3s)
  (if (>= (len feedinfo!outcome3s) 5)
    (= feedinfo!auto doc)))

(proc handle-outcome1(feedinfo doc)
  (if feedinfo!outcome3s
    (pop feedinfo!outcome3s)
    (let l (len (pushnew doc feedinfo!outcome1s))
      (if (>= l 6)      (= feedinfo!auto -1)
          (>= l 5)      (wipe feedinfo!auto)
          (>= l 3)      (wipe feedinfo!manual)))))



(def scan-feeds(keyword)
  (common:map keyword-feeds:canonicalize
              (flat:map split-urls tokens.keyword)))

(def feed-group-for(query)
  (let m (max-freq:map feed-group* scan-feeds.query)
    (erp "Group: " m)
    (if (no m)
      (flash "Hmm, this may suck. I don't know that site, so I'm showing
             random stories. Sorry! (now notifying Kartik)"))
    group-feeds*.m))

(def guess-type(entry)
  (if entry
    (if (feedinfo* symize.entry)     'feed
        docinfo*.entry               'doc
        (headmatch "http" entry)     'url
        (posmatch "//" entry)        'url
                                     'keyword)))



(def showlist(user station)
  (when (no station!showlist)
    (rebuild-showlist user station))
  station!showlist)

;; Pick 5 stories at a time
;;   Choose 1 lit doc in worklist
;;   Choose most recent story from upto 3 separate preferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds, avoiding recent and unpreferred feeds
;;   Fill remainder with most recent story from random unpreferred feeds, avoiding recent
;;   Fill remainder with most recent story from random feeds
(proc rebuild-showlist(user station)
  (erp "rebuild-showlist. Previous iter: " station!last-showlist)
  (erp "scanning preferred feeds: " station!showlist)
  (choose-from-preferred user station 3)
  (erp "scanning feeds by group: " station!showlist)
  (fill-by-group user station)
  (erp "scanning random feeds: " station!showlist)
  (fill-random user station)
  (erp "scanning unpreferred feeds: " station!showlist)
  (fill-random-unpreferred user station)
  (erp "done. candidates: " station!showlist)
  (zap rev station!showlist)
  (erp "after rev: " station!showlist)
  (= station!last-showlist station!showlist)
  (erp "done rebuild-showlist"))

(mac w/unread-avoiding-recent(user station l . body)
  `(let candidates ,l
    (nkeep [and (~recently-shown? ,station _)
                (most-recent-unread ,user _)]
           candidates)
    ,@body))

(def preferred-feeds(station)
  (keep [preferred? _] (vals station!preferred-feeds)))

(proc choose-from-preferred(user station n)
  (w/unread-avoiding-recent user station preferred-feeds.station
    (repeat n
      (whenlet feed randpos.candidates
        (erp "preferred: " feed)
        (push feed station!showlist)
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

(def most-recent-unread(user feed)
  (most doc-timestamp (rem [read? user _] feed-docs.feed)))

(def pick(user station)
  (ret ans (car (showlist user station))
    (if (pos guess-type.ans '(feed url))
      (zap [most-recent-unread user _] ans))))
      ; XXX: nothing unread left? (only dup feeds)

(prn "Done loading index.arc")
