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
  (fixedq 40
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

(init keyword-feeds-old* nil)
(dhash-nosave feed keyword "m-n"
  (map canonicalize
       (cons feed
             (flat:map split-urls
                       (flat:map tokens:striptags
                                 (vals:feedinfo* symize.feed))))))

(proc update-feed-keywords()
  (= keyword-feeds-old* keyword-feeds*
     keyword-feeds* (table))
  (= feed-keywords* (table) feed-keyword-nils* (table))
  (everyp feed feed-list* 100
    (feed-keywords feed))
  (everyp feed (tokens:slurp "feeds/Private/All") 100
    (feed-keywords feed))
  (wipe keyword-feeds-old*))

(init feed-groups* (table))
(init group-feeds* (table))
(proc read-group(g)
  (each feed (tokens:slurp:+ "feeds/" g)
    (push g feed-groups*.feed)
    (push feed group-feeds*.g)))

(proc update-feed-groups()
  (= feedgroups* (tokens:tostring:system "cd feeds; ls -d [A-Z]* |grep -v \"^$\\|^All$\\|^Private$\""))
  (= poorly-cleaned-feeds* (memtable (tokens:slurp "feeds/badclean")))
  (= feed-groups* (table)
     group-feeds* (table))
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
             'clock 100 'lastshow (seconds)
             'all (string:unique-id)
             'read (table) 'stations (table)))
  (ensure-station user userinfo*.user!all))

(proc ensure-station(user sname)
  (unless userinfo*.user!stations.sname
    (erp "new station: " sname)
    (inittab userinfo*.user!stations.sname
             'name    sname
             'created (seconds)
             'old-preferred (table)
             'sites   (table)
             'groups  (prefrangify
                        '("Economics" "Glamor" "Health" "Magazine" "News"
                          "Politics" "Science" "Technology")
                        100))))

(def ustation(user)
  (let s userinfo*.user!all
    userinfo*.user!stations.s))

(def read-list(user)
  ustation.user!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(defreg migrate() migrations*
  (wipe userinfo*.nil)
  (wipe feed-docs*.nil)
;?   (each (f d) feed-docs*
  (each (u ui) userinfo*
    (each (s st) ui!stations
;?     (each doc (keys ui!read)

      (each (g gi) st!groups
        (erp u " " s " " g))
    )
  ))

(proc mark-read(user doc outcome group)
  (with (station  ustation.user
         feed     lookup-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)
    (when (is doc (lookup-transient station!current))
      (expire-transient station!current))

    (case outcome
      "1" (handle-downvote user station feed group)
      "4" (handle-upvote user station feed group))))

(proc handle-upvote(user station feed group)
  (unless blank?.group
    (extend-prefer station!groups.group userinfo*.user!clock))
  (extend-prefer station!sites.feed   userinfo*.user!clock)
  ; XXX stuff that goes into old-preferred never goes back out
  (set station!old-preferred.feed))

(proc handle-downvote(user station feed group)
  (if (and (~blank? group)
           (~preferred? station!sites.feed userinfo*.user!clock))
    (extend-unprefer station!groups.group userinfo*.user!clock))
  (extend-unprefer station!sites.feed userinfo*.user!clock))

(proc create-query(user query)
  (erp user ": query " query)
  (unless blank?.query
    (nrem query userinfo*.user!queries)
    (push query userinfo*.user!queries)
    (let initfeeds scan-feeds.query
      (each feed initfeeds
        (handle-upvote user ustation.user feed ""))
      (or
        (set-current-from 'initfeeds user initfeeds)
        (set-current-from 'initgroups user (groups-feeds:feeds-groups initfeeds))
        (pick-from-similar-site user car.initfeeds)))))

(def pick-from-same-site(user feed)
  (or (set-current-from 'samesite user feed)
      (pick-from-similar-site user feed)))

(def pick-from-similar-site(user feed)
  (let queryfeeds (scan-feeds (car userinfo*.user!queries))
    (set-current-from 'similarsite user
                      (groups-feeds
                        (if (pos feed queryfeeds)
                          feeds-groups.queryfeeds
                          feed-groups*.feed)))))

(def groups-feeds(groups)
  (dedup:flat:map group-feeds* groups))
(def feeds-groups(feeds)
  (dedup:flat:map feed-groups* feeds))



(def lookup-feeds-for-keyword(word)
  ((or keyword-feeds-old* keyword-feeds*) word))

(def scan-feeds(keyword)
  (unless blank?.keyword
    (dedup:common:map lookup-feeds-for-keyword:canonicalize
                      (flat:map split-urls words.keyword))))

(def feeds-from-random-group(user station)
  (let curr userinfo*.user!clock
    (rem [unpreferred? (station!sites _) curr]
         (group-feeds*:randpos:keep [preferred? (station!groups _) curr]
                                    (keys station!groups)))))

(def random-story-from(group)
  (always newest
          (randpos group-feeds*.group)))



;; XXX Currently constant; should depend on 'temperature':
;;  a) how many preferred feeds the user has
;;  b) recent downvotes
;;  c) user input?
;; These should also influence whether we only show well-cleaned feeds.
(init preferred-prob* 0.8)

(def choose-feed(user station lastdoc)
  (randpick
    preferred-prob*  (let currquerygroupfeeds (groups-feeds:feeds-groups:scan-feeds:car userinfo*.user!queries)
                       (when (pos lookup-feed.lastdoc currquerygroupfeeds)
                         (choose-from 'latest-query-preferred
                                      (keep [preferred? (station!sites _)
                                                        userinfo*.user!clock]
                                            currquerygroupfeeds)
                                      user station)))
    preferred-prob*  (let currquerygroupfeeds (groups-feeds:feeds-groups:scan-feeds:car userinfo*.user!queries)
                       (when (pos lookup-feed.lastdoc currquerygroupfeeds)
                         (choose-from 'latest-query-pre
                                      currquerygroupfeeds
                                      user station)))
    preferred-prob*  (choose-from 'recent-preferred
                                  (keep (andf
                                          recent?
                                          [preferred? (station!sites _)
                                                      userinfo*.user!clock])
                                        (keys station!sites))
                                  user station
                                  recent-and-well-cleaned)
    preferred-prob*  (choose-from 'preferred
                                  (keep [preferred? (station!sites _)
                                                    userinfo*.user!clock]
                                        (keys station!sites))
                                  user station)
    preferred-prob*  (choose-from 'old-preferred
                                  (keys station!old-preferred)
                                  user station)
    1.01             (let currquerygroupfeeds (groups-feeds:feeds-groups:scan-feeds:car userinfo*.user!queries)
                       (when (pos lookup-feed.lastdoc currquerygroupfeeds)
                         (erp "latest query")
                         (choose-from 'latest-query
                                      currquerygroupfeeds
                                      user station)))
    ; XXX feeds-from-random-group will repeatedly try the same group
    1.01             (choose-from 'recent-group
                                  (keep recent?
                                        (feeds-from-random-group user station))
                                  user station
                                  recent-and-well-cleaned)
    1.01             (choose-from 'group
                                  (feeds-from-random-group user station)
                                  user station)
    1.01             (choose-from 'random
                                  nonnerdy-feed-list*
                                  user station)))

(persisted recent-feeds* (table))
(after-exec doc-feed(doc)
  (update recent-feeds* result most2.id doc-timestamp.doc))
(init daily-threshold* (* 60 60 24))
(def recent?(feed)
  (awhen recent-feeds*.feed
    (if (> (- (seconds) it) daily-threshold*)
      (wipe recent-feeds*.feed)
      it)))
(def recent-doc?(doc)
  (> (- (seconds) doc-timestamp.doc) daily-threshold*))

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

(def pick(user choosefn)
  (withs (s userinfo*.user!all
          station userinfo*.user!stations.s
          lastdoc (transval station!current))
    ;(lookup-or-generate-transient station!current
       (always [newest-unread user _]
               (choosefn user station lastdoc))));)
(after-exec pick(user dummy)
  (erp user " => " result))

(def set-current-from(name user feeds)
  (when feeds
    (whenlet feed (newest-unread-from user feeds)
      (erp user ": from " name)
      (let station ustation.user
        (= station!current
         (transient-value feed 500)))
      feed)))

(def newest-unread-from(user feeds)
  (if
    (~acons feeds)    (newest-unread user feeds)
    (single feeds)    (newest-unread user car.feeds)
                      (always [newest-unread user _] randpos.feeds)))

(after-exec choose-feed(user station lastdoc)
  (update-clock user))
(def update-clock(user)
  (let t0 (seconds)
    (if (> (- t0 userinfo*.user!lastshow) 3600)
      (zap [+ 10 _] userinfo*.user!clock)
      (++ userinfo*.user!clock))
    (= userinfo*.user!lastshow t0)))

(init history-size* 10)
(def recently-shown?(station feed)
  (pos feed
       (map lookup-feed (firstn history-size* station!read-list))))

(def docs(feed)
  (dl-elems feed-docs.feed))
(def newest(feed)
  (car docs.feed))
(def newest-unread(user feed)
  (find [~read? user _] docs.feed))



(def save-to-old-docs(doc)
  (= old-docs*.doc (obj url doc-url.doc  title doc-title.doc
                        site doc-site.doc  feedtitle doc-feedtitle.doc)))
(after-exec pick(user dummy)
  (unless old-docs*.result
    (save-to-old-docs result)))



; console helpers

(proc clear-user(user)
  (wipe userinfo*.user hpasswords*.user loggedin-users*.user)
  (save-table hpasswords* hpwfile*))

(proc gc-users()
  (map [wipe userinfo*._]
       (rem [or (userinfo*._ 'signedup) (logins* _)]
            keys.userinfo*)))

(proc gc-doc-dir()
  (erp "gc-doc-dir running")
  (everyp file (dir "urls") 1000
    (if (posmatch ".clean" file)
      (withs (doc (subst "" ".clean" file)
              feed (lookup-feed doc))
        (unless (pos doc (dl-elems feed-docs*.feed))
          (send-to-gc doc)))))
  (erp "gc-doc-dir done"))

(def add-old-preferred(user feed)
  (withs (s userinfo*.user!all
          st userinfo*.user!stations.s)
    (set userinfo*.user!preferred-feeds.feed)
    (set userinfo*.user!stations.s!old-preferred.feed)))

(def rename-feed(old new)
  (each (u ui) userinfo*
    (when (and ui!preferred-feeds ui!preferred-feeds.old)
      (swap ui!preferred-feeds.old ui!preferred-feeds.new))
    (each (s st) ui!stations
      (when (and st!old-preferred st!old-preferred.old)
        (swap st!old-preferred.old st!old-preferred.new)))))

(def purge-feed(feed)
  (each (u ui) userinfo*
    (when (and ui!preferred-feeds ui!preferred-feeds.feed) (prn u))
    (each (s st) ui!stations
      (when (and st!old-preferred st!old-preferred.feed) (prn u " " s)))))

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

(mac w/user(u . body)
  `(withs (user ,u
           ui userinfo*.user
           s ui!all
           st ui!stations.s)
    ,@body))
