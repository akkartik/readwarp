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

(unless (server-thread)
  (start-server:my-port))
