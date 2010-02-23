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
    (erp "new user: " user))
  (inittab userinfo*.user 'preferred-feeds (or load-feeds.user (table))
           'read (table) 'stations (table)))

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
      (= station!showlist (keep [most-recent-unread user _] scan-feeds.sname))
      (= station!last-showlist station!showlist)))
  (gen-groups user sname))

(proc migrate-stations()
  (each user (keys userinfo*)
    (each (sname station) userinfo*.user!stations
      (wipe station!showlist)
      (zap [map [cons _ nil] _] station!groups))))

(proc mark-read(user sname doc outcome)
  (if (is 4 outcome) (= outcome 2))
  (let station userinfo*.user!stations.sname
    (= outcome int.outcome)
    (erp outcome " " doc)
    (unless userinfo*.user!read.doc
      (= userinfo*.user!read.doc outcome)
        (push doc station!read-list)
        (pop station!showlist))

    (let feed doc-feed.doc
      (or= station!preferred (table))
      (case outcome
        1     (handle-downvote user station doc feed)
        2     (handle-upvote user station doc feed)))))

(proc handle-upvote(user station doc feed)
  (= station!preferred.feed (backoff doc 2))
  (erp "upvote: " station!preferred.feed))

(proc handle-downvote(user station doc feed)
  (erp "downvote: " station!preferred.feed)
  (if station!preferred.feed
    (do
      (erp "currently preferred")
      (backoff-add station!preferred.feed doc)
      (backoff-check station!preferred.feed))
    (do
      (erp "currently not in preferred; unpreferring " feed)
      (set station!unpreferred.feed))))



(def scan-feeds(keyword)
  (on-err
    (fn(ex) (erp "A: " keyword " " details.ex))
    (fn()
      (dedup:common:map keyword-feeds:canonicalize
                        (flat:map split-urls words.keyword)))))

(proc gen-groups(user sname)
  (let station userinfo*.user!stations.sname
    (when (no station!groups)
      (or= station!groups (dedup:keep id (flat:map feed-groups* scan-feeds.sname)))
      ;; HACK while my feeds are dominated by nerdy stuff.
      (if (len> station!groups 2)
        (nrem "Programming" station!groups))
      (if (len> station!groups 2)
        (nrem "Technology" station!groups))
      (erp "Groups: " station!groups)
      (unless station!groups
        (flash "Showing a few random stories")
        (= station!groups feedgroups*)))))

(def feeds(groups)
  (flat:map group-feeds* groups))

(def preferred-feeds(user station)
  (+ (keys station!preferred)
     (keep [userinfo*.user!preferred-feeds _]
           (feeds station!groups))))

(def feeds-from-groups(user station)
  (rem [station!unpreferred _]
       (feeds station!groups)))

(def guess-type(entry)
  (if entry
    (if (feedinfo* symize.entry)     'feed
        docinfo*.entry               'doc
        (headmatch "http" entry)     'url
        (posmatch "//" entry)        'url
                                     'keyword)))



;; For the main page show only preferred feeds.
(proc rebuild-showlist2(user station)
  (choose-from-preferred user station)
  (= station!last-showlist station!showlist))
(def showlist2(user station)
  (if (no station!showlist)
    (rebuild-showlist2 user station))
  station!showlist)
(def pick2(user station)
  (ret ans (car (showlist2 user station))
    (if (pos guess-type.ans '(feed url))
      (zap [most-recent-unread user _] ans))))

(def showlist(user station)
  (when (no station!showlist)
    (rebuild-showlist user station))
  station!showlist)

;; Pick 5 stories at a time
(= batch-size* 5)
;;   Fill each slot with most recent story from preferred feeds, avoiding recent, with some probability
;;   Fill remainder with most recent story from this group, avoiding recent
;;   Fill remainder with most recent story from random feeds, avoiding recent and unpreferred feeds
(proc rebuild-showlist(user station)
  (choose-from-preferred user station)
  (fill-by-group user station)
  (fill-random user station)
  (zap rev station!showlist)
  (= station!last-showlist station!showlist))

(def neglected-unread(user station feed)
  ((andf [~recently-shown? station _]
        [most-recent-unread user _])
    feed))

(mac choosing-random-neglected-unread(expr . body)
  `(withs (candidates   ,expr
           feed         (findg randpos.candidates
                               [neglected-unread user station _]))
      (when feed ,@body)))

;; XXX Currently constant; should depend on:
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
(= preferred-probability* 0.6)

(proc choose-from-preferred(user station)
  (repeat batch-size*
    (if (< (rand) preferred-probability*)
      (choosing-random-neglected-unread (preferred-feeds user station)
        (erp "preferred: " feed)
        (pushnew feed station!showlist)
        (pull feed candidates)))))

(proc fill-by-group(user station)
  (while (< (len station!showlist) batch-size*)
    (choosing-random-neglected-unread (feeds-from-groups user station)
      (erp "group: " feed)
      (pushnew feed station!showlist)
      (pull feed candidates))))

(proc fill-random(user station)
  (while (< (len station!showlist) batch-size*)
    (choosing-random-neglected-unread nonnerdy-feed-list*
      (erp "random: " feed)
      (pushnew feed station!showlist))
      (pull feed candidates)))

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
