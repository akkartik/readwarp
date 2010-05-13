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
             'clock 100 'lastshow (seconds)
             'all (stringify:unique-id)
             'read (table) 'stations (table)))
  (ensure-station user userinfo*.user!all))

(proc ensure-station(user sname)
  (unless userinfo*.user!stations.sname
    (erp "new station: " sname)
    (inittab userinfo*.user!stations.sname
             'name    sname
             'created (seconds)
             'preferred (table)
             'sites   (table)
             'groups  (memtable
                        '("Economics" "Glamor" "Health" "Magazine" "News"
                          "Politics" "Science" "Technology")))))

(def ustation(user)
  (let s userinfo*.user!all
    userinfo*.user!stations.s))

(def read-list(user)
  ustation.user!read-list)

(def read?(user doc)
  userinfo*.user!read.doc)

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

(proc mark-read(user doc outcome group)
  (with (station  ustation.user
         feed     lookup-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)
    (when (is doc (lookup-transient station!current))
      (wipe station!current))

    (or= station!preferred (table))
    (case outcome
      "1" (handle-downvote user station feed group)
      "4" (handle-upvote user station feed group))))

(proc handle-upvote(user station feed group)
  (unless blank?.group
    (extend-prefer station!groups.group userinfo*.user!clock))
  (extend-prefer station!sites.feed   userinfo*.user!clock)
  ; XXX stuff that goes into preferred never goes back out
  (set station!preferred.feed))

(proc handle-downvote(user station feed group)
  (if (and (~blank? group)
           (~preferred? station!sites.feed userinfo*.user!clock))
    (extend-unprefer station!groups.group userinfo*.user!clock))
  (extend-unprefer station!sites.feed userinfo*.user!clock))



(def scan-feeds(keyword)
  (dedup:common:map keyword-feeds:canonicalize
                    (flat:map split-urls words.keyword)))

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
(init preferred-prob* 0.6)

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
    preferred-prob*  (choose-from 'old-preferred
                                  (keys station!preferred)
                                  user station)
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

(def pick(user)
  (withs (s userinfo*.user!all
          station userinfo*.user!stations.s)
    (lookup-or-generate-transient station!current
       (always [newest-unread user _]
               (choose-feed user station)))))

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



(def save-to-old-docs(doc)
  (= old-docs*.doc (obj url doc-url.doc  title doc-title.doc
                        site doc-site.doc  feedtitle doc-feedtitle.doc)))
(after-exec pick(user)
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
