(include "www.arc")

(def submit-to-newsley(doc)
  (erp "submitting to newsley: " doc)
  (get-url:+
    "http://newsley.com/submit/via_script/?key=aldjfladjfladjfairuaoasjf"
    "&title=" (urlencode doc-title.doc)
    "&url=" doc-url.doc
    "&summary=" (urlencode:cut (striptags contents.doc) 0 200)))

; No defrep; sleep first to mitigate the chance of submitting from dev.
(thread "autosubmit-to-newsley"
  (while t
    (sleep 3600)
    (submit-to-newsley (random-story-from "Economics"))))
