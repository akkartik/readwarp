(def init-code()
  (include "utils.arc")
  (include "times.arc")

  (include "dlist.arc")
  (include "state.arc")
  (include "index.arc")
  (include "wrp.arc")

  (include "helpers.arc")
  (include "ui.arc")
  (include "ops.arc")
)
(init-code)

(unless (test-mode)
  (wipe disable-autosave*))
(do-any-migrations)

(def my-port()
  (on-err (fn(ex) 8080)
          (fn() (w/infile f "config.port" (read f)))))

(unless (server-thread)
  (start-server:my-port))

(quit-in:* 60 60 12) ; big hammer - we have a memory leak
