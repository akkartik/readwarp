(mac check-doc(doc . body)
  `(do
    (or= (docinfo* ,doc) (metadata ,doc))
    ,@body))

(def metadata(doc)
  (read-json-table (+ "urls/" doc ".metadata")))

(chunked-persisted docinfo*)
  (def doc-url(doc)
    (check-doc doc docinfo*.doc!url))
  (def doc-title(doc)
    (check-doc doc docinfo*.doc!title))
  (def doc-site(doc)
    (check-doc doc docinfo*.doc!site))
  (rhash doc feed "n-1"
    (check-doc doc docinfo*.doc!feed)
    rconsn.10)
  (def doc-feedtitle(doc)
    (check-doc doc docinfo*.doc!feedtitle))
  (def doc-timestamp(doc)
    (or pubdate.doc feeddate.doc 0))
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
  (= feedgroups* (tokens:tostring:system "cd feeds; ls -d [A-Z]* |grep -v \"^$\\|^All$\\|^Private$\""))
  (each group feedgroups*
    (read-group group)))

(when (no:test-mode)
(defrep update-feeds 3600
  (system "date")
  (prn "updating feed-list*")
  (= feed-list* (tokens:slurp "feeds/All"))
  (prn "updating feed-groups*")
  (update-feed-groups)
  (= nonnerdy-feed-list* (keep [set-subtract (feed-groups* _)
                                             '("Programming" "Technology")]
                            feed-list*))
  (= nonnerdy-feedcache* (make-rrand nonnerdy-feed-list*))
  (prn "updating feedinfo*")
  (update-feedinfo)
  (prn "updating feed index")
  (update-feed-keywords))
(wait update-feeds-init*)
)
(when (test-mode) ; {{{
  (= feed-list* (tokens:slurp "feeds/All"))
  (update-feed-groups)
  (= nonnerdy-feed-list* (keep [set-subtract (feed-groups* _)
                                             '("Programming" "Technology")]
                            feed-list*))
) ; }}}

(defscan index-doc "clean"
  (doc-feed doc))



(persisted userinfo* (table))

(def ensure-user(user)
  (unless userinfo*.user
    (erp "new user: " user)
    (inittab userinfo*.user
             'preferred-feeds (or load-feeds.user (table))
             'read (table) 'stations (table))))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(proc ensure-station(user sname)
  (ensure-user user)
  (unless userinfo*.user!stations.sname
    (erp "new station: " sname)
    (= userinfo*.user!stations.sname (table))
    (let station userinfo*.user!stations.sname
      (= station!name sname station!preferred (table) station!unpreferred (table))
      (= station!created (seconds))))
  (gen-groups user sname))

(defreg migrate-stations() migrations*
  (prn "migrate-stations")
  (wipe userinfo*.nil)
  (each (u ui) userinfo*
    (each (s st) ui
      (wipe st!groupcache)
      (wipe st!preferredcache)
      (wipe st!feedcache))
        ))

(proc mark-read(user sname doc outcome prune-feed prune-group)
  (with (station  userinfo*.user!stations.sname
         feed     doc-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)

    (or= station!preferred (table))
    (case outcome
      "1" (handle-downvote user station doc feed prune-feed prune-group)
      "2" (handle-upvote user station doc feed))))

(proc handle-upvote(user station doc feed)
  (= station!preferred.feed (backoff doc 2))
  (whenlet alls userinfo*.user!all
    (or= userinfo*.user!stations.alls!preferred (table))
    (= userinfo*.user!stations.alls!preferred.feed (backoff doc 2)))
  (each g (groups list.feed)
    (backoff-clear station!groups.g)))

(proc handle-downvote(user station doc feed prune-feed prune-group)
  (if (pos feed (preferred-feeds user station))
    (do
      (erp "currently preferred")
      (or= station!preferred.feed (backoff doc 2))
      (add-rrand station!preferredcache feed)
      (backoff-add station!preferred.feed doc)
      (backoff-check station!preferred.feed (or prune-feed prune-group)))
    (do
      ; sync preconditions to get here with borderline-unpreferred-group
      (erp "currently not in preferred; unpreferring " feed)
      (set station!unpreferred.feed)
      (del-rrand station!groupcache feed)
      (let curr-groups  (groups list.feed)
        (each g curr-groups
          (when station!groups.g
            (erp "trying to delete " g)
            (backoff-add station!groups.g feed)
            (erp "now: " station!groups.g)
            (backoff-check station!groups.g prune-group)
            (if prune-group (wipe station!feedcache))
            (erp "groups remaining: " (len-keys station!groups))))
        (when (empty station!groups)
          (= station!groups
             (backoffify (rem [pos _ curr-groups]
                             feedgroups*)
                         2)))))))

(def borderline-preferred-feed(user sname doc)
  (whenlet feed doc-feed.doc
    (and (pos feed (preferred-feeds user userinfo*.user!stations.sname))
         (backoff-borderline userinfo*.user!stations.sname!preferred.feed))))

(def borderline-unpreferred-group(user sname doc)
  (whenlet feed doc-feed.doc
    (and (~pos feed (preferred-feeds user userinfo*.user!stations.sname))
         (find [backoff-borderline userinfo*.user!stations.sname!groups._]
               (groups:list feed)))))



(def scan-feeds(keyword)
  (dedup:common:map keyword-feeds:canonicalize
                    (flat:map split-urls words.keyword)))

(def groups(feeds)
  (dedup:flat:map feed-groups* feeds))

(def initial-preferred-groups-for(user sname)
  (ret ans (dedup:keep id (groups scan-feeds.sname))
    ;; HACK while my feeds are dominated by nerdy stuff.
    (when (len> ans 2) (nrem "Programming" ans))
    (when (len> ans 2) (nrem "Technology" ans))

    (erp "Groups: " ans)
    (unless ans
      (when (neither blank.sname
                     (is sname userinfo*.user!all))
        (write-feedback user "" sname "" "Random stories for group"))
      (= ans feedgroups*))))

(proc gen-groups(user sname)
  (or= userinfo*.user!stations.sname!groups
       (backoffify (initial-preferred-groups-for user sname) 2)))

(def feeds(station)
  (or= station!feedcache
      (dedup:flat:map group-feeds* (keys station!groups))))

(def preferred-feeds(user station)
  (or= station!preferredcache
       (make-rrand
          (+ (keys station!preferred)
             (keep [userinfo*.user!preferred-feeds _]
                   feeds.station)))))

(def feeds-from-groups(user station)
  (or= station!groupcache
       (make-rrand
          (rem [station!unpreferred _]
               feeds.station))))

(def random-story-from(group)
  (most-recent
    (findg (randpos group-feeds*.group)
           most-recent)))



(init batch-size* 5)
(init rebuild-threshold* 2)
;; XXX Currently constant; should depend on:
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
(init preferred-probability* 0.6)
(init group-probability* 1.0)

(def new-feed(user station)
  (randpick
        preferred-probability*      (choose-from-preferred user station)
        group-probability*          (choose-from-group user station)
        1.01                        (choose-from-random user station)))

(def choose-from-preferred(user station)
  (let candidates (preferred-feeds user station)
    (findg rrand.candidates
           [most-recent-unread user _])))
(after-exec choose-from-preferred(user station)
  (when result (erp "preferred: " result)))

(def choose-from-group(user station)
  (let candidates (feeds-from-groups user station)
    (findg rrand.candidates
           [most-recent-unread user _])))
(after-exec choose-from-group(user station)
  (when result (erp "group: " result)))

(def choose-from-random(user station)
  (findg rrand.nonnerdy-feedcache*
         [most-recent-unread user _]))
(after-exec choose-from-random(user station)
  (when result (erp "random: " result)))

(def most-recent(feed)
  (most doc-timestamp feed-docs.feed))
(def most-recent-unread(user feed)
  (if feed
    (most doc-timestamp (rem [read? user _] feed-docs.feed))))

(def pick(user station)
  (always [most-recent-unread user _]
          (new-feed user station)))

(def load-feeds(user)
  (when (file-exists (+ "feeds/users/" user))
    (w/infile f (+ "feeds/users/" user)
      (w/table ans
        (whilet line (readline f)
          (zap trim line)
          (when (~empty line)
            (let url (car:tokens line)
              (when (headmatch "http" url)
                (set ans.url)))))))))
(after-exec load-feeds(user)
  (erp "found " len-keys.result " preferred feeds"))
