(without-updating-state

  (= docinfo*
      (obj
        "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
        "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
        "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
        "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
        "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

  (= feed-keywords*
     (obj
       "a.com/feed" '("a" "blog")
       "b.com/feed" '("b" "blog")))

  (= keyword-feeds*
     (obj
       "a" '("a.com/feed")
       "b" '("b.com/feed")
       "blog" '("a.com/feed" "b.com/feed")))

  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

  (= workspace (table))
  (add workspace "blog" 'keyword)

  (test-iso "add adds to workspace"
    (obj "blog" (obj type 'keyword))
    workspace)

  (= keyword-docs* (table))

  (propagate-keyword workspace "blog")
  (test-iso "propagate-keyword works"
    (obj "blog" (obj type 'keyword)
         "a.com/feed" (obj type 'feed
                           priors '("blog"))
         "b.com/feed" (obj type 'feed
                           priors '("blog")))
    workspace)

)
