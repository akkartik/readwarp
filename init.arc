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

(unless (server-thread)
  (start-server:my-port))

(new-station 0 "krugman")
(set-current-station-name 0 "krugman")
(time:propagate-keyword-to-doc 0 current-station.0 "krugman")
(time:mark-read 0 (next-doc 0) "read")
(time next-doc.0)

;? (each doc keys.docinfo*
;?   (doc-feed doc)
;?   (update-feed-keywords-via-doc doc))
;? (each feed keys.feedinfo*
;?   (update-feed-clusters-by-keyword stringify.feed))
;? (= feed-affinity* normalized-affinity-table.feed-clusters-by-keyword*)
