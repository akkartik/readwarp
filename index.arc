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

(dhash-nosave feed keyword "m-n"
  (map canonicalize
       (cons feed
             (flat:map split-urls
                       (flat:map tokens:striptags
                                 (vals:feedinfo* symize.feed))))))

(proc update-feed-keywords()
  (= feed-keywords* (table) keyword-feeds* (table) feed-keyword-nils* (table))
  ; XXX: queries here may fail
  (everyp feed feed-list* 100
    (if (is 0 (remainder index 50)) (sleep 1)) ; does this help with segfault?
    (feed-keywords feed)))

(init feed-groups* (table))
(init group-feeds* (table))
(proc read-group(g)
  (each feed (tokens:slurp:+ "feeds/" g)
    (push g feed-groups*.feed)
    (push feed group-feeds*.g)))

(proc update-feed-groups()
  (= feedgroups* (tokens:tostring:system "cd feeds; ls [A-Z]* |grep -v \"^All$\\|^Discard$\\|^Risque$\""))
  (each group feedgroups*
    (read-group group)))

(defrep update-feeds 3600
  (system "date")
  (prn "updating feed-list*")
  (= feed-list* (tokens:slurp "feeds/All"))
  (prn "updating feed-groups*")
  (update-feed-groups)
  (= nonnerdy-feed-list* (keep [set-subtract (feed-groups* _)
                                             '("Programming" "Technology")]
                            feed-list*))
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

(def ensure-user(user)
  (unless userinfo*.user
    (erp "new user: " user)
    (inittab userinfo*.user 'preferred-feeds (or load-feeds.user (table))
             'read (table) 'stations (table))))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(def stations(user)
  (keys userinfo*.user!stations))

(proc ensure-station(user sname)
  (ensure-user user)
  (when (no userinfo*.user!stations.sname)
    (erp "new station: " sname)
    (= userinfo*.user!stations.sname (table))
    (let station userinfo*.user!stations.sname
      (= station!name sname station!preferred (table) station!unpreferred (table))
      (= station!created (seconds))
      (= station!showlist (queue))
      (each feed (keep [most-recent-unread user _] scan-feeds.sname)
        (enq feed station!showlist))
      (new-thread "showlist" (fn() (rebuild-showlist user station)))
      (= station!last-showlist (queue))))
  (gen-groups user sname))

(defreg migrate-stations() migrations*
  (prn "migrate-stations")
  (each user (keys userinfo*)
    (each (sname station) userinfo*.user!stations
      (= station!showlist (queue)))))

(init history-size* 5)

(proc mark-read(user sname doc outcome prune-feed prune-group)
  (with (station  userinfo*.user!stations.sname
         feed     doc-feed.doc)
    (erp outcome " " doc)

    (= userinfo*.user!read.doc outcome)
    (push doc station!read-list)

    (let top (car:qlist station!showlist)
      (unless (is top doc-feed.doc)
        (erp "error: wrong feed")))

    (unless (show-same-station outcome user feed)
      (enqn (deq station!showlist)
            station!last-showlist
            history-size*))

    (or= station!preferred (table))
    (case outcome
      "1" (handle-downvote user station doc feed prune-feed prune-group)
      "2" (handle-upvote user station doc feed)
      "4" (handle-upvote user station doc feed))))

(def show-same-station(outcome user feed)
  (when (is outcome "4")
    (ret ans (most-recent-unread user feed)
      (unless ans
        (flash "No stories left in that site")))))

(proc handle-upvote(user station doc feed)
  (= station!preferred.feed (backoff doc 2))
  (erp "upvote: " station!preferred.feed))

(proc handle-downvote(user station doc feed prune-feed prune-group)
  (erp "downvote: " station!preferred.feed)
  (if (pos feed (preferred-feeds user station))
    (do
      (erp "currently preferred")
      (or= station!preferred.feed (backoff doc 2))
      (backoff-add station!preferred.feed doc)
      (backoff-check station!preferred.feed (or prune-feed prune-group)))
    (do
      ; sync preconditions to get here with borderline-unpreferred-group
      (erp "currently not in preferred; unpreferring " feed)
      (set station!unpreferred.feed)
      (with (prefd-groups (groups:preferred-feeds user station)
             this-groups  (groups list.feed))
        (erp "this-groups: " this-groups)
        (each g this-groups
          (erp g)
          (when station!groups.g
            (erp "trying to delete " g)
            (backoff-add station!groups.g feed)
            (erp "now: " station!groups.g)
            (backoff-check station!groups.g prune-group)
            (erp "groups remaining: " (len-keys station!groups))))
        (when (empty station!groups)
          (= station!groups
             (backoffify (rem [pos _ this-groups]
                             feedgroups*)
                         2)))))))

(def borderline-preferred-feed(user sname doc)
  (iflet feed doc-feed.doc
    (and (pos feed (preferred-feeds user userinfo*.user!stations.sname))
         (backoff-borderline userinfo*.user!stations.sname!preferred.feed))))

(def borderline-unpreferred-group(user sname doc)
  (iflet feed doc-feed.doc
    (and (~pos feed (preferred-feeds user userinfo*.user!stations.sname))
         (find [backoff-borderline userinfo*.user!stations.sname!groups._]
               (groups:list feed)))))



(def scan-feeds(keyword)
  (on-err
    (fn(ex) (erp "A: " keyword " " details.ex))
    (fn()
      (dedup:common:map keyword-feeds:canonicalize
                        (flat:map split-urls words.keyword)))))

(def groups(feeds)
  (dedup:flat:map feed-groups* feeds))

(def initial-preferred-groups-for(sname)
  (ret ans (dedup:keep id (groups scan-feeds.sname))
    ;; HACK while my feeds are dominated by nerdy stuff.
    (if (len> ans 2)
      (nrem "Programming" ans))
    (if (len> ans 2)
      (nrem "Technology" ans))

    (erp "Groups: " ans)
    (unless ans
      (flash "Showing a few random stories")
      (= ans feedgroups*))))

(proc gen-groups(user sname)
  (or= userinfo*.user!stations.sname!groups
       (backoffify initial-preferred-groups-for.sname 2)))

(def feeds(groups)
  (flat:map group-feeds* groups))

(def preferred-feeds(user station)
  (+ (keys station!preferred)
     (keep [userinfo*.user!preferred-feeds _]
           (feeds:keys station!groups))))

(def feeds-from-groups(user station)
  (rem [station!unpreferred _]
       (feeds:keys station!groups)))

(def guess-type(entry)
  (if entry
    (if (feedinfo* symize.entry)     'feed
        docinfo*.entry               'doc
        (headmatch "http" entry)     'url
        (posmatch "//" entry)        'url
                                     'keyword)))



;; For the main page show only preferred feeds.
;; XXX duplication
(def new-doc2(user station)
  (choose-from-preferred user station))
(proc add-to-showlist2(user station)
  (iflet doc (new-doc2 user station)
    (enq doc station!showlist)))
(proc rebuild-showlist2(user station)
  (repeat batch-size*
    (add-to-showlist2 user station)))
(def showlist2(user station)
  (when (< (qlen station!showlist) rebuild-threshold*)
    (erp "new thread2")
    (new-thread "showlist2" (fn() rebuild-showlist2 user station)))
  (until (> (qlen station!showlist) 0))
  (erp station!showlist)
  (qlist station!showlist))
(def pick2(user station)
  (ret ans (car (showlist2 user station))
    (if (pos guess-type.ans '(feed url))
      (zap [most-recent-unread user _] ans))))

(init batch-size* 5)
(init rebuild-threshold* 2)
;; XXX Currently constant; should depend on:
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
(init preferred-probability* 0.6)
(init group-probability* 1.0)

(def showlist(user station)
  (when (< (qlen station!showlist) rebuild-threshold*)
    (erp "new thread")
    (new-thread "showlist" (fn() (rebuild-showlist user station))))
  (until (> (qlen station!showlist) 0))
  (erp station!showlist)
  (qlist station!showlist))

(proc rebuild-showlist(user station)
  (repeat batch-size*
    (add-to-showlist user station)))

(proc add-to-showlist(user station)
  (iflet doc (new-doc user station)
    (enq doc station!showlist)))

(def new-doc(user station)
  (randpick
        preferred-probability*      (choose-from-preferred user station)
        group-probability*          (choose-from-group user station)
        1.01                        (choose-from-random user station)))

(def neglected-unread(user station feed)
  ((andf [~recently-shown? station _]
        [most-recent-unread user _])
    feed))

(def choose-from-preferred(user station)
  (let candidates (preferred-feeds user station)
    (findg randpos.candidates
           [neglected-unread user station _])))

(def choose-from-group(user station)
  (let candidates (feeds-from-groups user station)
    (findg randpos.candidates
           [neglected-unread user station _])))

(def choose-from-random(user station)
  (findg randpos.nonnerdy-feed-list*
         [neglected-unread user station _]))

(def recently-shown?(station feed)
  (or (pos feed (qlist station!last-showlist))
      (pos feed (qlist station!showlist))))

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
