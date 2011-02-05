(mac run-op(op ? args nil cooks nil)
  `(w/outstring o ((srvops* ',op) o (inst 'request 'args ,args 'cooks ,cooks))))

(without-updating-state
(shadowing docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a"))

(shadowing feedinfo*
    (obj a.com/feed (table)
         b.com/feed (table))

(shadowing feed-groups* (obj "feed1" "group1")

(shadowing contents (fn(doc) doc)

(shadowing userinfo*
    (obj
      "a" (obj preferred-feeds (table)
               read (table)
               clock 10
               lastshow 0
               stations (table)
               signup-showlist (queue)))

  (shadowing current-user (fn(req) "a")
    (test-ok "signup query works"
      (run-op ||)))

  (erp "waiting for thread to finish")
  (until (all dead (threads "signup-showlist"))
    (sleep 1))

))))))
