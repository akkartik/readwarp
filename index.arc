(const history-size* 30)



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
    send-to-gc))
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
    )
  ))

(proc mark-read(user doc)
  (unless userinfo*.user!read.doc
    (push doc ustation.user!read-list)
    (= userinfo*.user!read.doc "2")))



(def choose-feed(user station)
  (or
    (choose-from 'recent-popular-imported-feeds
                 (keys station!imported-feeds)
                 user station
                 recent-and-popular-and-well-cleaned)
    (choose-from 'recent-imported-feeds
                 (keys station!imported-feeds)
                 user station
                 recent-and-well-cleaned)
    (choose-from 'recent-popular
                 (keep recent?
                   (group-feeds* "Popular"))
                 user station
                 recent-feed-predicate)
    (choose-from 'popular
                 (group-feeds* "Popular")
                 user station)
    (choose-from 'imported-feeds
                 (keys station!imported-feeds)
                 user station)
    (choose-from 'random
                 nonnerdy-feed-list*
                 user station)))

(def feed-chooser(feed)
  (fn(user station)
    (if (newest-unread user feed)
      feed
      (choose-feed user station))))

(def group-chooser(group)
  (fn(user station)
    (or
      (choose-from 'recent-group
                   (keep recent? group-feeds*.group)
                   user station
                   recent-feed-predicate)
      (choose-from 'group
                   group-feeds*.group
                   user station)
      (choose-feed user station))))

(persisted recent-feeds* (table))
(after-exec doc-feed(doc)
  (update recent-feeds* result most2.idfn doc-timestamp.doc))
(const daily-threshold* (* 60 60 24))
(def recent?(feed)
  (awhen recent-feeds*.feed
    (if (> (- (seconds) it) daily-threshold*)
      wipe.it
      it)))
(def recent-doc?(doc)
  (> (- (seconds) doc-timestamp.doc)
     daily-threshold*))

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

(def recently-shown?(station feed)
  (pos feed
       (map lookup-feed (firstn (bounded-half:len station!imported-feeds)
                                station!read-list))))

(def bounded-half(x)
  (check (/ x 2) [> _ history-size*]
         history-size*))

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

; first run:
;   $ ls urls > filelist
; will run out of memory part-way through and crash racket; delete processed
; lines from filelist and restart.
(proc gc-doc-dir()
  (erp "gc-doc-dir running")
  (= i 0)
  (w/infile f "filelist"
    (whilet file ($.read-line f)
      (if (is 0 (remainder i 1000))
        (prn i " " file))
      ++.i
      (if (posmatch ".clean" file)
        (withs (doc (subst "" ".clean" file)
                feed (lookup-feed doc))
          (unless (pos doc docs.feed)
            (send-to-gc doc))))))
  (erp "gc-doc-dir done"))

(def add-imported-feeds(user feed)
  (withs (s userinfo*.user!all
          st userinfo*.user!stations.s)
    (set userinfo*.user!stations.s!imported-feeds.feed)))

(def rename-feed(old new)
  (each (u ui) userinfo*
    (each (s st) ui!stations
      (when (and st!imported-feeds st!imported-feeds.old)
        (swap st!imported-feeds.old st!imported-feeds.new)))))

(def purge-feed(feed)
  (each (u ui) userinfo*
    (each (s st) ui!stations
      (when (and st!imported-feeds st!imported-feeds.feed)
        (prn u " " s)
        (wipe st!imported-feeds.feed)))))

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

(def resort-feeds()
  (on f keys.feed-docs*
    (when (is 0 (mod index 10))
      (prn index " " f)
      (save-snapshot feed-docs* "tmp"))
    (zap [dlist:sort-by doc-timestamp dl-elems._] feed-docs*.f)))
