;? (= n (obj next '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
;?                  24 25 26 27 28 29 30 31)))

;? (= n (table))
;? (repeat 1000
;?   (push 3 n!next))

(= n (obj next (table)))

(def iter()
  (repeat 100000
    (= k n!next.750)))

(time:iter)
(quit)

(def init-code()
  (include "utils.arc")
  (include "skiplist.arc")

  (include "state.arc")
  (include "keywords.arc")
  (include "index.arc")

  (include "helpers.arc")
  (include "ui.arc")
)
(init-code)

(def my-port()
  (on-err (fn(ex) 8080)
          (fn() (w/infile f "config.port" (read f)))))

;? (unless (server-thread)
;?   (start-server:my-port))

(new-station 0 "krugman")
(set-current-station-name 0 "krugman")
(time:propagate-keyword-to-doc 0 current-station.0 "krugman")
(prn "== A")
(= propagates* 0 skiplist-travs* 0)
(time:mark-read 0 next-doc.0 "read")
(prn skiplist-travs* " travs in " propagates* " propagates")
(prn "== B")
(= propagates* 0 skiplist-travs* 0)
(time:mark-read 0 next-doc.0 "read")
(prn skiplist-travs* " travs in " propagates* " propagates")
;? (prn "== C")
;? (time:mark-read 0 next-doc.0 "skip")
;? (prn "== D")
;? (time:mark-read 0 next-doc.0 "skip")
;? (prn "== E")
;? (time:mark-read 0 next-doc.0 "read")
(quit)

;? (each doc keys.docinfo*
;?   (doc-feed doc)
;?   (update-feed-keywords-via-doc doc))
;? (each feed keys.feedinfo*
;?   (update-feed-clusters-by-keyword stringify.feed))
;? (= feed-affinity* normalized-affinity-table.feed-clusters-by-keyword*)
