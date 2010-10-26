(def nullop2(x y))

(mac run-op(op (o args (table)) (o cooks (table)))
  `(w/outstring o ((srvops* ',op) o (obj args ,args cooks ,cooks))))



(def cache-control(static-file)
  (on-err
    (fn(ex) static-file)
    (fn()
      (let filename (+ "www/static/" static-file)
        (+ static-file "?" ($:file-or-directory-modify-seconds filename))))))

(def jstag(src)
  (prn "<script src=\"" cache-control.src "\"></script>"))
(def csstag(src)
  (prn "<link rel=\"stylesheet\" href=\"" cache-control.src "\"></link>"))

(def header()
  (tag title (pr "Readwarp"))
  (tag head
    (prn "<meta name=\"robots\" content=\"nofollow\"/>")
    (prn "<link rel=\"icon\" href=\"/favicon.ico\"/>")

    (csstag "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/ui-lightness/jquery-ui.css")
    (jstag "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js")
    (jstag "http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js")
    (jstag "jquery.ba-hashchange.min.js")
    (jstag "jquery.hotkeys.js")

    (csstag "main.css")
    (jstag "utils.js")
    (jstag "application.js")))

(def is-prod(req)
  (~is "127.0.0.1" req!ip))

(def jsesc(s)
  (subst "\\'" "'" (subst "\\\"" "\"" s)))



(let server-thread* (ifcall server-thread)
  (proc start-server((o port 8080))
    (stop-server)
    (= server-thread* (new-thread "server" (fn() (asv port))))
    (push server-thread* scan-registry*))
  (proc stop-server()
    (when server-thread* (kill-thread server-thread*)))
  (def server-thread()
    server-thread*))

(def kill-handlers()
  (each (name thread) threads*
    (when (and (pos name '("handler" "timeout"))
               (~dead thread))
      (kill-thread thread))))
