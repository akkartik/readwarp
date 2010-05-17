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

  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

)))))))))))))
