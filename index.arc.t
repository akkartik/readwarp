(without-updating-state
(shadowing flash id
(shadowing docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a"))

(shadowing keyword-feeds*
    (obj
      "a" '("a.com/feed")
      "b" '("b.com/feed")
      "blog" '("a.com/feed" "b.com/feed"))

(shadowing feed-groups* (obj "feed1" "group1"
                             "a.com/feed" "group2")

(shadowing group-feeds* (obj "group2" "a.com/feed")

(shadowing feedgroups* '("group1" "group2")

  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

  (= userinfo* (table))
  (ensure-user nil)
  (ensure-station nil "a")
  (test-iso "gen-groups works"
    (obj "group2" '("group2" 2 nil))
    ((userinfo*.nil!stations "a") 'groups))

  (test-iso "feeds works"
    '("a.com/feed")
    (feeds:keys ((userinfo*.nil!stations "a") 'groups)))

  (ensure-station nil "")
  (let station (userinfo*.nil!stations "")
    (shadowing doc-feed (fn(doc) "feed0")
      (handle-downvote nil station "doc0" "feed0")
      (test-ok "downvoting a non-preferred feed puts it immediately in the unpreferred list"
        (station!unpreferred "feed0")))

    (shadowing doc-feed (fn(doc) "feed1")
      (test-iso "starting randomly across all groups"
        (sort < feedgroups*)
        (sort < (keys station!groups)))

      (handle-upvote nil station "doc1" "feed1")
      (test-ok "upvoting a non-preferred feed puts it immediately in the preferred list"
        (station!preferred "feed1"))

      (handle-downvote nil station "doc2" "feed1")
      (test-iso "downvoting a preferred feed doesn't demote it the first time"
        '("doc1" 2 ("doc2"))
        (station!preferred "feed1"))

      (handle-upvote nil station "doc3" "feed1")
      (test-iso "upvoting a preferred feed resets its situation"
        '("doc3" 2 nil)
        (station!preferred "feed1"))

      (handle-downvote nil station "doc4" "feed1")
      (test-iso "non-consecutive downvotes don't demote preferred feeds"
        '("doc3" 2 ("doc4"))
        (station!preferred "feed1"))

      (handle-downvote nil station "doc5" "feed1")
      (test-nil "consecutive downvotes demotes preferred feeds"
        (station!preferred "feed1"))

      (handle-downvote nil station "doc6" "feed1")
      (handle-downvote nil station "doc7" "feed1")
      (test-iso "consecutive downvotes demote group"
        '("group2")
        (keys station!groups))
    )

    (shadowing doc-feed (fn(doc) "a.com/feed")

      (handle-downvote nil station "doc8" "a.com/feed")
      (handle-downvote nil station "doc9" "a.com/feed")
      (test-iso "demoting the last group resets groups to all but that groups"
        '("group1")
        (keys station!groups))

    )

  )

)))))))
