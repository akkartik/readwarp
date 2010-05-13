(init docinfo* (table))
(persisted old-docs* (table))
(proc send-to-gc(doc)
  (w/outfile f "fifos/gc" (disp (+ doc #\newline) f)))

(mac check-doc(doc . body)
  `(do
    (or= (docinfo* ,doc) (metadata ,doc))
    (errsafe ,@body)))

(def metadata(doc)
  (read-json-table (+ "urls/" doc ".metadata")
                   [old-docs* doc]))

(def doc-url(doc)
  (check-doc doc docinfo*.doc!url))
(def doc-title(doc)
  (check-doc doc docinfo*.doc!title))
(def doc-site(doc)
  (check-doc doc docinfo*.doc!site))
(def lookup-feed(doc)
  (check-doc doc docinfo*.doc!feed))
(rhash doc feed "n-1"
  lookup-feed.doc
  (fixedq 10
    ;on-delete
      (fn(doc)
        (send-to-gc doc))))
(def doc-feedtitle(doc)
  (check-doc doc docinfo*.doc!feedtitle))
(def doc-timestamp(doc)
  (or pubdate.doc feeddate.doc 0))
(def pubdate(doc)
  (check-doc doc docinfo*.doc!date))
(def feeddate(doc)
  (check-doc doc docinfo*.doc!feeddate))
(def contents(doc)
  (or (errsafe:slurp (+ "urls/" doc ".clean"))
      ""))

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
  (= poorly-cleaned-feeds* (memtable (tokens:slurp "feeds/badclean")))
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
  (set update-feeds-init*)
  (prn "updating feed index")
  (update-feed-keywords))
(wait update-feeds-init*)

(unless (test-mode)
(defscan index-doc "clean"
  (doc-feed doc))
)



(persisted userinfo* (table))

(def ensure-user(user)
  (unless userinfo*.user
    (erp "new user: " user)
    (inittab userinfo*.user
             'preferred-feeds (or load-feeds.user (table))
             'clock 100 'lastshow (seconds)
             'read (table) 'stations (table))))

(def read-list(user station)
  userinfo*.user!stations.station!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(proc ensure-station(user sname)
  (ensure-user user)
  (unless userinfo*.user!stations.sname
    (erp "new station: " sname)
    (inittab userinfo*.user!stations.sname
             'name sname
             'unpreferred (table)
             'created (seconds)))
  (init-groups user sname)
  (init-preferred user sname))

(defreg migrate() migrations*
  (prn "running migrations")
  (wipe userinfo*.nil)
  (wipe feed-docs*.nil)
;?   (each (f d) feed-docs*
  (each (u ui) userinfo*
    (= ui!clock 100
       ui!lastshow (seconds))
    (each (s st) ui!stations
;?     (each doc (keys ui!read)

      (= st!sites (table))
      (each (f v) st!preferred
        (= st!sites.f (prefrange 100)))
      (each (f v) st!unpreferred
        (= st!sites.f (prefrange 99 99)))

      (unless st!oldgroups
        (= st!oldgroups st!groups
           st!groups (table)))
      (each (g v) st!oldgroups
        (= st!groups.g (prefrange 100)))
    )
  ))

(proc mark-read(user sname doc outcome prune-feed group prune-group)
  (with (station  userinfo*.user!stations.sname
         feed     lookup-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)
    (when (is doc (lookup-transient station!current))
      (wipe station!current))

    (or= station!preferred (table))
    (case outcome
      "1" (handle-downvote user station doc feed prune-feed group prune-group)
      "4" (handle-upvote user station doc feed))))

(proc handle-upvote(user station feed group)
  (extend-prefer station!groups.group userinfo*.user!clock)
  (extend-prefer station!sites.feed   userinfo*.user!clock))

(proc handle-downvote(user station feed group)
  (if (and (~blank? group)
           (~preferred? station!sites.feed userinfo*.user!clock))
    (extend-unprefer station!groups.group userinfo*.user!clock))
  (extend-unprefer station!sites.feed userinfo*.user!clock))



(def scan-feeds(keyword)
  (dedup:common:map keyword-feeds:canonicalize
                    (flat:map split-urls words.keyword)))

(def groups(feeds)
  (dedup:flat:map feed-groups* feeds))

(def initial-preferred-groups-for(user sname)
  (ret ans (dedup:keep id (groups scan-feeds.sname))
    ;; HACK while my feeds are dominated by nerdy stuff.
    (when (len> ans 2) (nrem "Programming" ans))

    (erp "Groups: " ans)
    (unless ans
      (when (neither blank.sname
                     (is sname userinfo*.user!all))
        (write-feedback user "" sname "" "Random stories for group"))
      (= ans '("Economics" "Glamor" "Health" "Magazine" "News" "Politics"
               "Science" "Technology")))))

(proc init-groups(user sname)
  (let station userinfo*.user!stations.sname
    (or= station!initfeeds scan-feeds.sname)
    (lookup-or-generate-transient station!current
       (always [newest-unread user _]
               (randpos station!initfeeds)))
    (or= station!groups (backoffify (initial-preferred-groups-for user sname)
                                    2))))

(proc init-preferred(user sname)
  (let station userinfo*.user!stations.sname
    (or= station!preferred
         (backoffify (keep [userinfo*.user!preferred-feeds _] feeds.station)
                     2))))

(def feeds(station)
  (dedup:flat:map group-feeds* (keys station!groups)))

(def feeds-from-groups(user station)
  (rem [station!unpreferred _] feeds.station))

(def random-story-from(group)
  (always newest
          (randpos group-feeds*.group)))



;; XXX Currently constant; should depend on:
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
(init preferred-probability* 0.6)

(def choose-feed(user station)
  (randpick
        preferred-probability* (choose-from 'recent-preferred
                                            (keep recent?
                                                  (keys station!preferred))
                                            user station
                                            recent-and-well-cleaned)
        preferred-probability* (choose-from 'preferred (keys station!preferred)
                                            user station)
        1.01                   (choose-from 'recent-group
                                            (keep recent?
                                                  (feeds-from-groups user station))
                                            user station
                                            recent-and-well-cleaned)
        1.01                   (choose-from 'group
                                            (feeds-from-groups user station)
                                            user station)
        1.01                   (choose-from 'random
                                            nonnerdy-feed-list*
                                            user station)))

(persisted recent-feeds* (table))
(after-exec doc-feed(doc)
  (update recent-feeds* result most2.id doc-timestamp.doc))
(def recent?(feed)
  (awhen recent-feeds*.feed
    (if (> (- (seconds) it) (* 60 60 24))
      (wipe recent-feeds*.feed)
      it)))
(def recent-doc?(doc)
  (> (- (seconds) doc-timestamp.doc) (* 60 60 24)))

(def choose-from(msg candidates user station (o pred good-feed-predicate))
  (ret result
          (findg (randpos candidates)
                 (pred user station))
    (when result (erp msg ": " result))))

(def good-feed-predicate(user station)
  (andf
    [newest-unread user _]
    [~recently-shown? station _]))

(def recent-feed-predicate(user station)
  (andf
    (good-feed-predicate user station)
    [recent-doc?:newest-unread user _]))

(def recent-and-well-cleaned(user station)
  (andf
    (good-feed-predicate user station)
    [recent-doc?:newest-unread user _]
    [~poorly-cleaned-feeds* _]))

(def pick(user station)
  (lookup-or-generate-transient station!current
     (always [newest-unread user _]
             (choose-feed user station))))

(after-exec choose-feed(user station)
  (update-clock user))
(def update-clock(user)
  (let t0 (seconds)
    (if (> (- t0 userinfo*.user!lastshow) 3600)
      (zap [+ 10 _] userinfo*.user!clock)
      (++ userinfo*.user!clock))
    (= userinfo*.user!lastshow t0)))

(def recently-shown?(station feed)
  (pos feed
       (map lookup-feed (firstn history-size* station!read-list))))

(def docs(feed)
  (dl-elems feed-docs.feed))
(def newest(feed)
  (car docs.feed))
(def newest-unread(user feed)
  (find [~read? user _] docs.feed))



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

(def save-to-old-docs(doc)
  (= old-docs*.doc (obj url doc-url.doc  title doc-title.doc
                        site doc-site.doc  feedtitle doc-feedtitle.doc)))
(after-exec pick(user station)
  (unless old-docs*.result
    (save-to-old-docs result)))



; console helpers

(def update-preferred-feeds(user)
  (each f (keys load-feeds.user)
    (unless userinfo*.user!preferred-feeds.f
      (erp f))
    (set userinfo*.user!preferred-feeds.f)
    (let gs userinfo*.user!all
      (unless userinfo*.user!stations.gs!unpreferred.f
        (unless userinfo*.user!stations.gs!preferred.f
          (erp "global: " f))
        (set userinfo*.user!stations.gs!preferred.f)))))

(proc clear-user(user)
  (wipe userinfo*.user hpasswords*.user loggedin-users*.user)
  (save-table hpasswords* hpwfile*))

(proc clear-users()
  (map [wipe userinfo*._]
       (rem [or (userinfo*._ 'signedup) (logins* _)]
            keys.userinfo*)))

(def feedstats(user)
  (let r (dedup:map lookup-feed (keys userinfo*.user!read))
    (rem [pos _ r] (keys userinfo*.user!preferred-feeds))))

(def rename-feed(old new)
  (each (u ui) userinfo*
    (swap ui!preferred-feeds.old ui!preferred-feeds.new)
    (each (s st) ui!stations
      (swap st!preferred.old st!preferred.new)
      (swap st!unpreferred.old st!unpreferred.new))))

(def add-preferred(user feed)
  (withs (s userinfo*.user!all
          st userinfo*.user!stations.s)
    (set userinfo*.user!preferred-feeds.feed)
    (= userinfo*.user!stations.s!preferred.feed (backoff feed 2))))

(proc gc-doc-dir()
  (erp "gc-doc-dir running")
  (everyp file (dir "urls") 1000
    (if (posmatch ".clean" file)
      (withs (doc (subst "" ".clean" file)
              feed (lookup-feed doc))
        (unless (pos doc (dl-elems feed-docs*.feed))
          (send-to-gc doc)))))
  (erp "gc-doc-dir done"))
