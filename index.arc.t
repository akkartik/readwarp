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
  (= feed-keyword-nils* (table))

  (= keyword-feeds*
     (obj
       "a" '("a.com/feed")
       "b" '("b.com/feed")
       "blog" '("a.com/feed" "b.com/feed")))

  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

  (= workspace (table))
  (add-query workspace "blog")

  (test-iso "add adds to workspace"
    (obj "blog" (obj type 'keyword
                     priors '(query)))
    workspace)

  (= keyword-docs* (table))

  (propagate-keyword workspace "blog")
  (test-iso "propagate-keyword works"
    (obj "blog" (obj type 'keyword
                     priors '(query))
         "a.com/feed" (obj type 'feed
                           priors '("blog"))
         "b.com/feed" (obj type 'feed
                           priors '("blog")))
    workspace)

  (= doc-feeds* (table))
  (= feed-docs* (table))
  (= doc-feeds* (obj "a_com_a" "a.com/feed"))
  (= feed-docs* (obj "a.com/feed" '("a_com_a")))
  (= feed-keywordcount* (obj "a.com/feed" (table)))
  (= normalized-keyword-clusters* (table))
  (= feed-affinity* (normalized-affinity-table normalized-keyword-clusters*))

  (propagate-feed workspace "a.com/feed")
  (test-iso "propagate-feed works"
    (obj "blog"       (obj type 'keyword
                           priors '("a.com/feed" query))
         "a"          (obj type 'keyword
                           priors '("a.com/feed"))
         "a_com_a"    (obj type 'doc
                           priors '("a.com/feed"))
         "a.com/feed" (obj type 'feed
                           priors '("blog"))
         "b.com/feed" (obj type 'feed
                           priors '("blog")))
    workspace)

;?   (propagate-doc

)
