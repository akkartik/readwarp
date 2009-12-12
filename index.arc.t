; About to mock global data; disable persistence
(kill-thread save-thread*)

  (= docinfo*
      (obj
        "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
        "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
        "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
        "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
        "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

  (= userinfo*
      (obj
        0 (obj read (table))))

  (ok (no:current-user-read "a_com_a"))

  (def site-docs2(doc)
    (keep (site-docs 0 "" doc) keys.docinfo*))
  (def feed-docs2(doc)
    (keep (feed-docs 0 "" doc) keys.docinfo*))

  (test-iso "site-docs should return docs from same site"
    '("a_com_a" "a_com_b" "a_com_c")
    (sort < (site-docs2 "a.com")))

  (= userinfo*
      (obj
        0 (obj
            read (Set "a_com_a")
            stations (obj
                      "a" (table)))))

  (test-iso "feed-docs should return docs from same feed"
    '("a_com_c" "b_com_0")
    (sort < (feed-docs2 "a.com/feed2")))

  (ok (current-user-read "a_com_a") "current-user-read should work")

  (test-iso "gen-docs should return unread site-docs and feed-docs for feed"
    '("a_com_b" "a_com_c" "b_com_0")
    (sort < (gen-docs 0 "a.com/feed")))

  (test-iso "gen-docs should return unread site-docs and feed-docs for site"
    '("a_com_b" "a_com_c" "b_com_0")
    (sort < (gen-docs 0 "a.com")))

  (test-iso "gen-docs should return unread site-docs and feed-docs for doc"
    '("a_com_b" "a_com_c" "b_com_0")
    (sort < (gen-docs 0 "a.com_c")))

  (test-iso "gen-docs should return unread site-docs and feed-docs for url"
    '("a_com_b" "a_com_c" "b_com_0")
    (sort < (gen-docs 0 "a.com/c")))

  (let docmock (obj
      "a_com_a" '("a" "b" "c")
      "a_com_b" '("a")
      "b_com_0" '("a"))
    (dhash doc keyword "m-n"
      docmock.doc)
    (each doc keys.docmock doc-keywords.doc))

  (test-iso "gen-docs should include docs with keyword overlap"
    '("a_com_b" "a_com_c" "b_com_0" "b_com_a")
    (sort < (gen-docs 0 "b.com/0")))

; No persistence; stop running
(quit)
