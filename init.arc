(include "keywords.arc")
(def init-code()
  (include "utils.arc")
  (include "skiplist.arc")
  (include "helpers.arc")

  (include "state.arc")
  (include "index.arc")

  (include "ui.arc")
)
(init-code)
(wipe disable-autosave*) ; after persistent data is loaded
(do-migration)

(def my-port()
  (on-err (fn(ex) 8080)
          (fn() (w/infile f "config.port" (read f)))))

(unless (server-thread)
  (start-server:my-port))
