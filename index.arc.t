(without-updating-state
(shadowing flash id
(shadowing docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a"))

(shadowing doc-feeds* (table)
(each doc keys.docinfo*
    (doc-feed doc))

(shadowing feed-list* '("a.com/feed" "b.com/feed")
(shadowing nonnerdy-feed-list* '("a.com/feed" "b.com/feed")

(shadowing feedinfo*
    (obj
      a.com/feed (obj "site" "a.com"
                      "url" "http://a.com/feed"
                      "description" "a blog")
      b.com/feed (obj "site" "b.com"
                      "url" "http://b.com/feed"
                      "description" "b blog"))

(shadowing keyword-feeds* (table)
(shadowing feed-keywords* (table)
(shadowing feed-keyword-nils* (table)
(update-feed-keywords)

(shadowing feedgroups* '("group1" "group2" "group3")
(shadowing group-feeds*
    (obj
      "group1" (list "feed2" "b.com/feed")
      "group2" (list "a.com/feed" "b.com/feed")
      "group3" (list "a.com/feed"))
(shadowing feed-groups*
    (w/table tb
      (each (k v) group-feeds*
        (each elem v
          (push k tb.elem))))

(shadowing userinfo* (table)
(ensure-user nil)

(shadowing new-thread (fn(name f) (f))
(ensure-station nil "a")

  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

  (test-iso "init-groups works"
    (obj "group2" '("group2" 2 nil)
         "group3" '("group3" 2 nil))
    ((userinfo*.nil!stations "a") 'groups))

  (test-iso "feeds works"
    '("a.com/feed" "b.com/feed")
    (feeds (userinfo*.nil!stations "a")))

(or= userinfo*.nil!all (stringify:unique-id))
(ensure-station nil userinfo*.nil!all)

(ensure-station nil "randomstring")
(let station (userinfo*.nil!stations "randomstring")
  (test-iso "unknown keywords start out selecting feeds randomly across all groups"
    (sort < feedgroups*)
    (sort < (keys station!groups)))

  ; XXX Assumption: up/down don't ever call doc-feed
  (handle-downvote nil station "b_com_a" "b.com/feed" t "group2" t)
  (test-ok "downvoting a non-preferred feed puts it immediately in the unpreferred list"
    (station!unpreferred "b.com/feed"))

  (handle-downvote nil station "b_com_a" "b.com/feed" t "group2" t)
  (test-iso "consecutive downvotes demote group"
    '("group1" "group3")
    (sort < (keys station!groups)))

  (handle-upvote nil station "doc1" "feed1")
  (test-ok "upvoting a non-preferred feed puts it immediately in the preferred list"
    (station!preferred "feed1"))

  (test-ok "upvoting a feed in a channel also puts it in the global channel's preferred list"
    (((userinfo*.nil!stations userinfo*.nil!all) 'preferred) "feed1"))

  (handle-downvote nil station "doc2" "feed1" t "" t)
  (test-iso "downvoting a preferred feed doesn't demote it the first time"
    '("doc1" 2 ("doc2"))
    (station!preferred "feed1"))

  (handle-upvote nil station "doc3" "feed1")
  (test-iso "upvoting a preferred feed resets its situation"
    '("doc3" 2 nil)
    (station!preferred "feed1"))

  (handle-downvote nil station "doc4" "feed1" t "" t)
  (test-iso "non-consecutive downvotes don't demote preferred feeds"
    '("doc3" 2 ("doc4"))
    (station!preferred "feed1"))

  (handle-downvote nil station "doc5" "feed1" t "" t)
  (test-nil "consecutive downvotes demotes preferred feeds"
    (station!preferred "feed1"))

  (handle-downvote nil station "doc8" "a.com/feed" t "group2" t)
  (handle-downvote nil station "doc9" "a.com/feed" t "group2" t)
  (test-iso "demoting the last group resets groups to all but that groups"
    '("group3" "group1")
    (keys station!groups))

  (handle-downvote nil station "doc10" "feed2" t "group1" t)
  (test-iso "downvoting a non-preferred feed doesn't demote its group"
    '("group1" 2 ("feed2"))
    (station!groups "group1"))

  (handle-upvote nil station "doc11" "feed2")
  (test-iso "upvoting a non-preferred feed resets its group's situation"
    '("group1" 2 nil)
    (station!groups "group1"))

))))))))))))))))
