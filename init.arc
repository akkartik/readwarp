(def init-code()
  (include "utils.arc")
  (include "state.arc")
  (include "index.arc")
  (include "helpers.arc")
  (include "ui.arc"))
(init-code)
(load-state)

;? (def save-thread()
;?   (while t
;?     (sleep 10)
;?     (save-state)))
;? (init save-thread* (new-thread save-thread))
;? 
;? (def scan-thread()
;?   (while t
;?     (sleep 3600)
;?     (scan-state)))
;? (init scan-thread* (new-thread scan-thread))

(def my-port()
  (on-err (fn(ex) 8080)
          (fn() (w/infile f "config.port" (read f)))))
(start-server:my-port)
