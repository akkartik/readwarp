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

(def header(req)
  (tag title (pr "Readwarp"))
  (tag head
    (prn "<meta name=\"robots\" content=\"nofollow\"/>")
    (prn "<link rel=\"icon\" href=\"/favicon.ico\"/>")

    (csstag "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/themes/ui-lightness/jquery-ui.css")
    (jstag "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js")
    (jstag "http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.2/jquery-ui.min.js")
    (jstag "jquery.ba-hashchange.min.js")

    (csstag "main.css")
    (jstag "application.js")))

(def is-prod(req)
  (~is "127.0.0.1" req!ip))



(mac sharebutton body
  `(tag (span class 'rwsharebutton)
    ,@body))

(def copy-widget(text)
  (sharebutton
    (pr:+
      "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\"
              width=\"110\"
              height=\"14\"
              id=\"clippy\" >
      <param name=\"movie\" value=\"/clippy.swf\"/>
      <param name=\"allowScriptAccess\" value=\"always\" />
      <param name=\"quality\" value=\"high\" />
      <param name=\"scale\" value=\"noscale\" />
      <param NAME=\"FlashVars\" value=\"text=#{text}\">
      <param name=\"bgcolor\" value=\"#ffffff\">
      <embed src=\"/clippy.swf\"
             width=\"110\"
             height=\"14\"
             name=\"clippy\"
             quality=\"high\"
             allowScriptAccess=\"always\"
             type=\"application/x-shockwave-flash\"
             pluginspage=\"http://www.macromedia.com/go/getflashplayer\"
             FlashVars=\"text=" text "\"
             bgcolor=\"#ffffff\"
      />
      </object>")))



(def clear()
  (tag (div class "rwclear")))

(def flash(msg)
  (tag (div class "rwflash") prn.msg))

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
