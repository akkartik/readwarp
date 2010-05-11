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
  (each (f d) feed-docs*
    (zap dlist feed-docs*.f)
;?   (each (u ui) userinfo*
;?     (each (s st) ui!stations
;?     (each doc (keys ui!read)
;?     )
  ))

(proc mark-read(user sname doc outcome prune-feed group prune-group)
  (with (station  userinfo*.user!stations.sname
         feed     lookup-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)
    (when (is doc station!current)
      (wipe station!current))

    (or= station!preferred (table))
    (case outcome
      "1" (handle-downvote user station doc feed prune-feed group prune-group)
      "4" (handle-upvote user station doc feed))))

(proc handle-upvote(user station doc feed)
  (= station!preferred.feed (backoff doc 2))
  (each g (groups list.feed)
    (backoff-clear station!groups.g))

  (set userinfo*.user!preferred-feeds.feed)
  (whenlet global-sname userinfo*.user!all
    (unless (is station!name global-sname)
      (init-preferred user global-sname)
      (= userinfo*.user!stations.global-sname!preferred.feed
         (backoff doc 2)))))

(proc handle-downvote(user station doc feed prune-feed group prune-group)
  (if (pos feed (keys station!preferred))
    (backoff-add-and-check station!preferred.feed doc prune-feed)
    ; sync preconditions to get here with borderline-unpreferred-group
    (unprefer-feed station feed group prune-group)))

(proc unprefer-feed(station feed group prune-group)
  (set station!unpreferred.feed)
  (if group
    (backoff-add-and-check station!groups.group feed prune-group)
    (each g (groups list.feed)
      (backoff-add-and-check station!groups.g feed nil)))
  (when (empty station!groups)
    (= station!groups
       (backoffify (rem group feedgroups*) 2))))

(def borderline-preferred-feed(user sname doc)
  (whenlet feed lookup-feed.doc
    (let station userinfo*.user!stations.sname
      (and (pos feed (keys station!preferred))
           (backoff-borderline station!preferred.feed)))))

(def borderline-unpreferred-group(user sname doc)
  (whenlet feed lookup-feed.doc
    (let station userinfo*.user!stations.sname
      (and (~pos feed (keys station!preferred))
           (find [backoff-borderline station!groups._]
                 (groups list.feed))))))



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

(proc init-groups(user sname)
  (let station userinfo*.user!stations.sname
    (or= station!initfeeds scan-feeds.sname)
    (or= station!current (always [most-recent-unread user _]
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
  (most-recent
    (findg (randpos group-feeds*.group)
           most-recent)))



;; XXX Currently constant; should depend on:
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
(init preferred-probability* 0.6)

(def choose-feed(user station)
  (randpick
        preferred-probability* (choose-from 'preferred (keys station!preferred)
                                            user station)
        1.01                   (choose-from 'group (feeds-from-groups user station)
                                            user station)
        1.01                   (choose-from 'random nonnerdy-feed-list*
                                            user station)))

(def choose-from(msg candidates user station)
  (ret result
          (findg (randpos candidates)
                 (good-feed-predicate user station))
    (when result (erp msg ": " result))))

(def good-feed-predicate(user station)
  (if userinfo*.user!signedup
    (andf
      [most-recent-unread user _]
      [~recently-shown? station _])
    (andf
      [~poorly-cleaned-feeds* _]
      [most-recent-unread user _]
      [~recently-shown? station _])))

(def pick(user station)
  (or= station!current
       (always [most-recent-unread user _]
               (choose-feed user station))))

(def recently-shown?(station feed)
  (pos feed
       (map lookup-feed (firstn history-size* station!read-list))))

(def docs(feed)
  (dl-elems feed-docs.feed))
(def most-recent(feed)
  (car docs.feed))
(def most-recent-unread(user feed)
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
