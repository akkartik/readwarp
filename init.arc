(def init-code()
  (include "utils.arc")
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
;? (start-server:my-port)

;? (new-station 0 "krugman")
;? (no:time:propagate 0 "krugman")

(each doc keys.docinfo*
  (doc-feed doc)
  (update-feed-keywords-via-doc doc))
(each feed keys.feedinfo*
  (update-feed-clusters-by-keyword stringify.feed))
(= feed-affinity* normalized-affinity-table.feed-clusters-by-keyword*)
