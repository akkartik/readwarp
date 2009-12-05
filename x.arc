(def current-user()
  0)

(def Set args
  (w/table ans
    (each k args
      (= (ans k) t))))

(def current-user-read(doc)
  (((userinfo* (current-user)) 'read) doc))

(def doc-from-site(site)
  (car:keep [and (no:current-user-read _)
                 (iso site docinfo*._!site)]
            (keys docinfo*)))
