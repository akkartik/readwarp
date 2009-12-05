(def current-user()
  0)

(def time-ago(s)
  (- (seconds) s))

(def Set args
  (w/table ans
    (each k args
      (= (ans k) t))))

(def current-user-read(doc)
  (((userinfo* (current-user)) 'read) doc))

(def site-docs(site)
  (keep [and (no:current-user-read _)
                 (iso site docinfo*._!site)]
            (keys docinfo*)))

(mac random-unread()
  (cons 'rand-choice (rem [current-user-read _] (keys docinfo*))))
