(mac check-doc(doc . body)
  `(do
    (or= (docinfo* ,doc) (metadata ,doc))
    ,@body))

(chunked-persisted docinfo*)
  (def doc-url(doc)
    (check-doc doc docinfo*.doc!url))
  (def doc-title(doc)
    (check-doc doc docinfo*.doc!title))
  (def doc-site(doc)
    (check-doc doc docinfo*.doc!site))
  (rhash doc feed "n-1"
    (check-doc doc docinfo*.doc!feed)
    rconsuniq)
  (def doc-feedtitle(doc)
    (check-doc doc docinfo*.doc!feedtitle))
  (def doc-timestamp(doc)
    (or pubdate.doc feeddate.doc))
  (def pubdate(doc)
    (check-doc doc docinfo*.doc!date))
  (def feeddate(doc)
    (check-doc doc docinfo*.doc!feeddate))
  (def contents(doc)
    (slurp (+ "urls/" doc ".clean")))

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
                       (flat:map tokens:striptags
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
        "Glamor"
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
  (read-json-table (+ "urls/" doc ".metadata")))

(defscan index-doc "clean"
  (doc-feed doc))

(def scan-doc-dir()
  (everyp file (dir "urls") 1000
    (if (posmatch ".clean" file)
      (let doc (subst "" ".clean" file)
        (unless docinfo*.doc prn.doc)
        doc-feed.doc))))



(persisted userinfo* (table))

(def new-user(user)
  (erp "new user: " user)
  (inittab userinfo*.user 'preferred-feeds (or load-feeds.user (table))
           'read (table) 'stations (table)))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(def stations(user)
  (keys userinfo*.user!stations))

(proc new-station(user sname)
  (erp "new-station: " sname)
  (when (no userinfo*.user!stations.sname)
    (= userinfo*.user!stations.sname (table))
    (let station userinfo*.user!stations.sname
      (= station!name sname)
      (= station!showlist (keep [most-recent-unread user _] scan-feeds.sname))
      (= station!feeds (feed-group-for user sname))
      (= station!preferred-feeds (memtable:keep [userinfo*.user!preferred-feeds _]
                                                station!feeds)))))

(proc mark-read(user sname doc outcome)
  (let station userinfo*.user!stations.sname
    (= outcome int.outcome)
    (unless userinfo*.user!read.doc
      (= userinfo*.user!read.doc outcome)
        (push doc station!read-list)
        (pop station!showlist))

    (let feed doc-feed.doc
      (or= station!preferred-feeds (table))
      (case outcome
        1     (wipe station!preferred-feeds.feed)
        2     (set station!preferred-feeds.feed)
        4     (set station!preferred-feeds.feed))
)))



(def scan-feeds(keyword)
  (dedup:common:map keyword-feeds:canonicalize
                    (flat:map split-urls words.keyword)))

(def feed-group-for(user query)
  (let m (max-freq:map feed-group* scan-feeds.query)
    (erp "Group: " m)
    (unless m
      (flash "Hmm, this may suck. I don't know that site, so I'm showing
             random stories. Sorry! (now notifying Kartik)")
      (write-feedback user query "" "random results for query"))
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

(proc choose-from-preferred(user station n)
  (w/unread-avoiding-recent user station (keys station!preferred-feeds)
    (repeat n
      (whenlet feed randpos.candidates
        (erp "preferred: " feed)
        (pushnew feed station!showlist)
        (pull feed candidates)))))

(proc fill-by-group(user station)
  (w/unread-avoiding-recent user station station!feeds
    (while (and candidates
                (< (len station!showlist) 5))
      (let feed randpos.candidates
        (erp "group: " feed)
        (pushnew feed station!showlist)
        (pull feed candidates)))
    (if (< (len station!showlist) 5)
      (erp "RAN OUT OF GROUP"))))

(proc fill-random(user station)
  (if (< (len station!showlist) 5)
    (w/unread-avoiding-recent user station feed-list*
      (while (and candidates
                  (< (len station!showlist) 5))
        (let feed randpos.candidates
          (unless (and station!preferred-feeds
                       station!preferred-feeds.feed)
            (pushnew feed station!showlist))
          (pull feed candidates))))))

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

(def load-feeds(user)
  (if (file-exists (+ "feeds/" user))
    (w/infile f (+ "feeds/" user)
      (w/table ans
        (whilet line (readline f)
          (zap trim line)
          (if (~empty line)
            (let url (car:tokens line)
              (if (headmatch "http" url)
                (set ans.url)))))))))
(after-exec load-feeds(user)
  (erp "found " len-keys.result " preferred feeds"))

(prn "Done loading index.arc")
