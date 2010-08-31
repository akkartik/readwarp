(include "keywords.arc")
(def init-code()
  (include "utils.arc")
  (include "times.arc")

  (include "skiplist.arc")
  (include "dlist.arc")

  (include "state.arc")
  (include "index.arc")
  (include "wrp.arc")

  (include "helpers.arc")
  (include "js.arc")
  (include "ui.arc")
  (include "signup.arc")
  (include "ops.arc")
)
(init-code)

(unless (test-mode)
  (wipe disable-autosave*))
(do-migration)

(def my-port()
  (on-err (fn(ex) 8080)
          (fn() (w/infile f "config.port" (read f)))))

(unless (server-thread)
  (start-server:my-port))
