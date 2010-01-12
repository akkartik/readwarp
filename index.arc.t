(without-updating-state

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
  (= feed-affinity* (normalized-affinity-table normalized-keyword-clusters*))
  (= doc-affinity* (normalized-affinity-table keyword-docs*))



  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

  (= userinfo* (table))
  (new-user 0)
  (new-station 0 "blog")
  (set-current-station-name 0 "blog")
  (= station current-station.0)

  (test-iso "new-station adds query to workspace"
    (obj
      "blog" (obj type 'keyword created 0 priors '(query)))
    station!workspace)



  (propagate-one 0 station "a.com/feed" 'feed "blog")
  (test-iso "propagate-one inserts one element into workspace"
    (obj
      "blog" (obj type 'keyword created 0 priors '(query))
      "a.com/feed" (obj type 'feed created 0 priors '("blog")))
    station!workspace)

  (propagate-one 0 station "blog" 'keyword "a.com/feed")
  (test-iso "propagate-one adds to prior of existing element"
    (obj
      "blog" (obj type 'keyword created 0 priors '("a.com/feed" query))
      "a.com/feed" (obj type 'feed created 0 priors '("blog")))
    station!workspace)

  (propagate-keyword 0 station "blog")
  (test-iso "propagate-keyword works"
    (obj "blog" (obj type 'keyword created 0 priors '("a.com/feed" query))
         "a.com/feed" (obj type 'feed created 0 priors '("blog"))
         "b.com/feed" (obj type 'feed created 0 priors '("blog")))
    station!workspace)

  (propagate-feed 0 station "a.com/feed")
  (test-iso "propagate-feed works"
    (obj "blog"       (obj type 'keyword created 0 priors '("a.com/feed" query))
         "a"          (obj type 'keyword created 0 priors '("a.com/feed"))
         "a_com_a"    (obj type 'doc created 0 priors '("a.com/feed"))
         "a.com/feed" (obj type 'feed created 0 priors '("blog"))
         "b.com/feed" (obj type 'feed created 0 priors '("blog")))
    station!workspace)

  (propagate-doc 0 station "a_com_a")
  (test-iso "propagate-doc works"
    (obj "blog"       (obj type 'keyword created 0 priors '("a.com/feed" query))
         "a"          (obj type 'keyword created 0 priors '("a.com/feed"))
         "a_com_a"    (obj type 'doc created 0 priors '("a.com/feed"))
         "a.com/feed" (obj type 'feed created 0 priors '("a_com_a" "blog"))
         "b.com/feed" (obj type 'feed created 0 priors '("blog")))
    station!workspace)

)
