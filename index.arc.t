(without-updating-state
(shadowing userinfo*

  (test-ok "guess-type nil" (no:guess-type nil))

  (= docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

  (= keyword-docs* (table))
  (= doc-keywords* (table))
  (= doc-keyword-nils* (table))
  (= feedinfo* (table))

  (= feed-keywords*
     (obj
       "a.com/feed" '("a" "blog")
       "b.com/feed" '("b" "blog")))
  (= feed-keyword-nils* (table))
  (= keyword-feeds*
     (obj
       "a" '("a.com/feed")
       "b" '("b.com/feed")
       "blog" '("a.com/feed" "b.com/feed")))

  (= doc-feeds* (obj "a_com_a" "a.com/feed"))
  (= doc-feed-nils* (table))
  (= feed-docs* (obj "a.com/feed" '("a_com_a")))
  (= feed-keywordcount* (obj "a.com/feed" (table)))
  (= normalized-keyword-clusters* (table))



  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

))
