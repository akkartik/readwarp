(without-updating-state
(shadowing keyword-feeds*
     (obj
       "a" '("a.com/feed")
       "b" '("b.com/feed")
       "blog" '("a.com/feed" "b.com/feed"))



  (test-ok "scan-feeds finds feeds containing a keyword"
    (pos "a.com/feed" (scan-feeds "blog")))

))
