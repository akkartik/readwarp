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


  (= userinfo* (table))
  (new-user 0)
  (new-station 0 "blog")
  (= station (userinfo*.0!stations "blog"))

  (shadowing doc-feed (fn(doc) "aaa")
    (preferred-feed-manual-set station "abc" t)
    (test-iso "manually setting preferred status for feed"
      (obj manual t auto "abc")
      (station!preferred-feeds "aaa"))

    (handle-outcome3 station "aaa" "1")
    (test-iso "outcome3 increments outcome3s"
      (obj manual t auto "abc" outcome3s '("1"))
      (station!preferred-feeds "aaa"))

    (handle-outcome1 station "aaa" "2")
    (test-iso "outcome1 decrements outcome3s"
      (obj manual t auto "abc")
      (station!preferred-feeds "aaa"))

    (handle-outcome1 station "aaa" "3")
    (test-iso "outcome1 increments outcome1s"
      (obj manual t auto "abc" outcome1s '("3"))
      (station!preferred-feeds "aaa"))

    (handle-outcome1 station "aaa" "4")
    (handle-outcome1 station "aaa" "5")
    (test-iso "3 outcome1s reset manual"
      (obj auto "abc" outcome1s '("5" "4" "3"))
      (station!preferred-feeds "aaa"))

    (handle-outcome1 station "aaa" "6")
    (handle-outcome1 station "aaa" "7")
    (test-iso "5 outcome1s reset auto"
      (obj outcome1s '("7" "6" "5" "4" "3"))
      (station!preferred-feeds "aaa"))

    (handle-outcome1 station "aaa" "8")
    (test-iso "6 outcome1s 'unprefer' auto"
      (obj auto -1 outcome1s '("8" "7" "6" "5" "4" "3"))
      (station!preferred-feeds "aaa"))



    (= (station!preferred-feeds "aaa") ())
    (handle-outcome3 station "aaa" "9")
    (handle-outcome3 station "aaa" "10")
    (handle-outcome3 station "aaa" "11")
    (handle-outcome3 station "aaa" "12")
    (test-iso "4 outcome3s increment"
      (obj outcome3s '("12" "11" "10" "9"))
      (station!preferred-feeds "aaa"))

    (handle-outcome3 station "aaa" "13")
    (test-iso "5th outcome3 sets auto"
      (obj auto "13" outcome3s '("13" "12" "11" "10" "9"))
      (station!preferred-feeds "aaa"))
  )

))
