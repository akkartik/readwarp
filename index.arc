(const history-size* 10)



(init docinfo* (table))
(persisted old-docs* (table))
(proc send-to-gc(doc)
  (w/outfile f "fifos/gc" (pushline doc f)))

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
  (set update-feeds-init*))
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
             'clock 100
             'all (string:unique-id)
             'read (table) 'stations (table)))
  (ensure-station user userinfo*.user!all))

(proc ensure-station(user sname)
  (unless userinfo*.user!stations.sname
    (erp "new station: " sname)
    (inittab userinfo*.user!stations.sname
             'name    sname
             'created (seconds)
             'imported-feeds (table)
             'sites   (table))))

(def ustation(user)
  (let s userinfo*.user!all
    userinfo*.user!stations.s))

(def read-list(user)
  ustation.user!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

(defreg migrate-index() migrations*
  (wipe userinfo*.nil)
  (wipe feed-docs*.nil)
;?   (each (f d) feed-docs*
  (each (u ui) userinfo*
    (each (s st) ui!stations
;?     (each doc (keys ui!read)
;?       (each (g gi) st!groups
      (= st!sites (table))
    )
  ))

(proc mark-read(user doc)
  (unless userinfo*.user!read.doc
    (push doc ustation.user!read-list)
    (= userinfo*.user!read.doc "2")))

(proc vote(user doc outcome)
  (with (station  ustation.user
         feed     lookup-feed.doc)
    (erp outcome " " doc)
    (= userinfo*.user!read.doc outcome)
    (or= station!sites.feed (prefinfo userinfo*.user!clock))
    (= station!sites.feed!clock userinfo*.user!clock)
    (case outcome
      "1" (zap [* 3 _] station!sites.feed!blackout)
      "4" (zap [bounded-half _] station!sites.feed!blackout))))

(def preferred?(prefinfo clock)
  (or no.prefinfo
       (> clock (+ prefinfo!clock prefinfo!blackout))))

(def prefinfo(clock)
  (obj clock clock blackout history-size*))

(def bounded-half(blackout)
  (check (/ blackout 2)   [> _ history-size*]
         history-size*))



(def groups-feeds(groups)
  (dedup:flat:map group-feeds* groups))
(def feeds-groups(feeds)
  (dedup:flat:map feed-groups* feeds))

(def random-story-from(group)
  (always newest
          (randpos group-feeds*.group)))



(const preferred-prob* 0.8)
(def choose-feed(user station)
  (randpick
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
    preferred-prob*  (choose-from 'recent-popular-imported-feeds
                                  (keys station!imported-feeds)
                                  user station
                                  recent-and-popular-and-well-cleaned)
    preferred-prob*  (choose-from 'recent-imported-feeds
                                  (keys station!imported-feeds)
                                  user station
                                  recent-and-well-cleaned)
    1.01             (choose-from 'recent-popular
                                  (keep recent?
                                    (group-feeds* "Popular"))
                                  user station
                                  recent-feed-predicate)
    1.01             (choose-from 'popular
                                  (group-feeds* "Popular")
                                  user station)
    1.01             (choose-from 'imported-feeds
                                  (keys station!imported-feeds)
                                  user station)
    1.01             (choose-from 'random
                                  nonnerdy-feed-list*
                                  user station)))

(def feed-chooser(feed)
  (fn(user station)
    (if (newest-unread user feed)
      feed
      (choose-feed user station))))

(def group-chooser(group)
  (fn(user station)
    (randpick
      1.01             (choose-from 'recent-group
                                    (keep recent? group-feeds*.group)
                                    user station
                                    recent-feed-predicate)
      1.01             (choose-from 'group
                                    group-feeds*.group
                                    user station)
      1.01             (choose-feed user station))))

(persisted recent-feeds* (table))
(after-exec doc-feed(doc)
  (update recent-feeds* result most2.idfn doc-timestamp.doc))
(const daily-threshold* (* 60 60 24))
(def recent?(feed)
  (awhen recent-feeds*.feed
    (if (> (- (seconds) it) daily-threshold*)
      (wipe recent-feeds*.feed)
      it)))
(def recent-doc?(doc)
  (> (- (seconds) doc-timestamp.doc) daily-threshold*))

(def choose-from(msg candidates user station ? pred good-feed-predicate)
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

(def recent-and-popular-and-well-cleaned(user station)
  (andf
    (recent-and-well-cleaned user station)
    [popular? _]))

(def popular?(feed)
  (find feed (group-feeds* "Popular")))

(def pick(user choosefn)
  (let sname userinfo*.user!all
     (always [newest-unread user _]
             (choosefn user userinfo*.user!stations.sname))))
(after-exec pick(user choosefn)
  (erp user " => " result))

(def newest-unread-from(user feeds)
  (if
    ~acons.feeds    (newest-unread user feeds)
    single.feeds    (newest-unread user car.feeds)
                    (always [newest-unread user _] randpos.feeds)))

(after-exec pick(user choosefn)
  (++ userinfo*.user!clock))

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
(after-exec pick(user choosefn)
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

(def add-imported-feeds(user feed)
  (withs (s userinfo*.user!all
          st userinfo*.user!stations.s)
    (set userinfo*.user!preferred-feeds.feed)
    (set userinfo*.user!stations.s!imported-feeds.feed)))

(def rename-feed(old new)
  (each (u ui) userinfo*
    (when (and ui!preferred-feeds ui!preferred-feeds.old)
      (swap ui!preferred-feeds.old ui!preferred-feeds.new))
    (each (s st) ui!stations
      (when (and st!imported-feeds st!imported-feeds.old)
        (swap st!imported-feeds.old st!imported-feeds.new)))))

(def purge-feed(feed)
  (each (u ui) userinfo*
    (when (and ui!preferred-feeds ui!preferred-feeds.feed)
      (prn u)
      (wipe ui!preferred-feeds.feed))
    (each (s st) ui!stations
      (when (and st!imported-feeds st!imported-feeds.feed)
        (prn u " " s)
        (wipe st!imported-feeds.feed))
      (when (and st!sites st!sites.feed)
        (prn u " " s)
        (wipe st!sites.feed)))))

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
  `(withs (u ,u
           ui userinfo*.u
           s ui!all
           st ui!stations.s)
    ,@body))
