(def doc-from-site(site)
  (car:keep [iso site docinfo*._!site] (keys docinfo*)))
