(mac run-op(op (o args) (o cooks))
  `(w/outstring o ((srvops* ',op) o (inst 'request 'args ,args 'cooks ,cooks))))

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

(shadowing feedinfo*
    (obj a.com/feed (table)
         b.com/feed (table))

(shadowing feed-groups* (obj "feed1" "group1")

(shadowing contents (fn(doc) doc)

  (test-ok "station queries work"
    (run-op station '(("seed" "blog"))))

(shadowing userinfo*
    (obj
      "a" (obj preferred-feeds (table)
               read (table)
               stations (table)
               signup-showlist (queue)))

  (shadowing current-user (fn(req) "a")
    (test-ok "signup query works"
      (run-op begin nil)))

))))))))
