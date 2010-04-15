(= ignore-ips* (memtable '("69.162.77.202" "69.162.127.2")))

(def nullop2(x y))

(mac run-op(op (o args (table)) (o cooks (table)))
  `(w/outstring o ((srvops* ',op) o (obj args ,args cooks ,cooks))))



(mac paginate(req id url n max-index . block)
  (let (params body) (kwargs block '(nextcopy "next" prevcopy "prev"))
    `(withs (start-index (int2:arg req "from")
             end-index (+ start-index ,n))
        (paginate-nav ,id ,url ,n start-index end-index ,max-index ',params)
        ,@body
        (paginate-nav ,id ,url ,n start-index end-index ,max-index ',params))))

(mac paginate-bottom(req id url n max-index . block)
  (let (params body) (kwargs block '(nextcopy "next" prevcopy "prev"))
    `(withs (start-index (int2:arg req "from")
             end-index (+ start-index ,n))
        ,@body
        (paginate-nav ,id ,url ,n start-index end-index ,max-index ',params))))

(def paginate-nav(id url n start-index end-index max-index (o params (table)))
  (let n (- end-index start-index)
    (tag (div class "rwpaginate")
      (if (params 'reverse)
        (do
          (paginate-next id url n start-index end-index max-index params)
          (pr "&nbsp;")
          (paginate-prev id url n start-index end-index params))
        (do
          (paginate-prev id url n start-index end-index params)
          (pr "&nbsp;")
          (paginate-next id url n start-index end-index max-index params))))))

(def paginate-prev(id url n start-index end-index params)
  (if (> start-index 0)
    (tag (a href "#" onclick (+ "inline('" id "', '" url udelim.url "from=" (max 0 (- start-index n)) "')"))
      (pr (or (params 'prevcopy) "&larr; prev")))
    (pr (or (params 'prevcopy) "&larr; prev"))))

(def paginate-next(id url n start-index end-index max-index params)
  (if (< end-index max-index)
    (tag (a href "#" onclick (+ "inline('" id "', '" url udelim.url "from=" end-index "')"))
      (pr (or (params 'nextcopy) "next &rarr;")))
    (pr (or (params 'nextcopy) "next &rarr;"))))

(def udelim(s)
  (if (posmatch "?" s) "&" "?"))



(mac toggle-icon(id template url reset-img set-img test-fn)
  `(jstogglelink ,id
      ,(rewrite reset-img 'IMG template) ,url
      ,(rewrite set-img 'IMG template) ,url
      ,test-fn))

; calling convention for fn args: var storage -> storage
(mac deftoggle(name var test-fn
               set-copy set-fn reset-copy reset-fn)
  (withs (name-str (stringify name)
          addop (symize "add-to-" name-str)
          remop (symize "remove-from-" name-str)
          storage (symize name-str "s-table")
          link_fn (symize name-str "_link")
          var-str (stringify var))
    `(let dummy nil
       (unless (bound ',storage) (= ,storage nil))
       (defop ,addop req (= ,storage (,set-fn (arg req ,var-str) ,storage)))
       (defop ,remop req (= ,storage (,reset-fn (arg req ,var-str) ,storage)))
       (def ,link_fn(,var)
          (jstogglelink ,var
              ,reset-copy (+ ,(+ "/" (stringify remop) "?" var-str "=") (eschtml ,var))
              ,set-copy (+ ,(+ "/" (stringify addop) "?" var-str "=") (eschtml ,var))
              (,test-fn ,var ,storage))))))

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

(mac header extra-directives
  `(do
    (tag title (pr "Readwarp"))
    (tag head
      (prn "<meta name=\"robots\" content=\"nofollow\"/>")
      (prn "<link rel=\"icon\" href=\"/favicon.ico\"/>")
      (csstag "main.css")

      (jstag "http://api.mixpanel.com/site_media/js/api/mixpanel.js")
      (tag script
        (pr "try {
              var mpmetrics = new MixpanelLib(\"65cfd23d70294fdadc5c7211e3814d8c\");
            } catch(err) {}"))

      (jstag "prototype.js")
      (jstag "effects.js")
      (jstag "controls.js")
      (jstag "dragdrop.js")
      (jstag "application.js")
      ,@extra-directives)))

(def signup-funnel-analytics(prod n user)
  (let funnel-name (if prod
                     "\"Signup1 Production\""
                     "\"Signup1\"")
    (tag script
      (pr "mpmetrics.track_funnel(" funnel-name ", " n ", \"" n "\", "
          (alist-json abtests.user) ");"))))

(def abtest(user key (o options))
  (or= userinfo*.user!abtests (table))
  (unless (or userinfo*.user!abtests.key options)
    (erp "Error: abtest " key " with no options"))
  (ret ans (or= userinfo*.user!abtests.key randpos.options)
    (erp "abtest: " key " " ans)))

(def init-funnel-property(user key val)
  (or= userinfo*.user!abtests (table))
  (or= userinfo*.user!abtests.key randpos.options))

(def set-funnel-property(user key val)
  (= userinfo*.user!abtests.key val))

(def abtests(user)
  (init-abtests user)
  (only.tablist userinfo*.user!abtests))

(def alist-json(al)
  (tostring
    (pr "{")
    (each (k v) al
      (if (~is k caar.al)
        (pr ", "))
      (pr "\"" stringify.k "\": \"" stringify.v "\""))
    (pr "}")))

(def is-prod(req)
  (~is "127.0.0.1" req!ip))



(mac jstogglelink-sub(c text url (o styl))
  `(tag (a class ,c onclick "toggleLink(this); return jsget(this);" href ,url style ,styl) ,text))
(def display(flag)
  (if flag
    "display:inline"
    "display:none"))
(mac jstogglelink(id text0 url0 text1 url1 which)
  `(do
    (jstogglelink-sub (+ ,id "_off") ,text0 ,url0 (display ,which))
    (jstogglelink-sub (+ ,id "_on") ,text1 ,url1 (display (not ,which)))))

(def copywidget(text)
  (pr:+
    "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\"
            width=\"110\"
            height=\"16\"
            id=\"clippy\" >
    <param name=\"movie\" value=\"/clippy.swf\"/>
    <param name=\"allowScriptAccess\" value=\"always\" />
    <param name=\"quality\" value=\"high\" />
    <param name=\"scale\" value=\"noscale\" />
    <param NAME=\"FlashVars\" value=\"text=#{text}\">
    <param name=\"bgcolor\" value=\"#ffffff\">
    <embed src=\"/clippy.swf\"
           width=\"110\"
           height=\"16\"
           name=\"clippy\"
           quality=\"high\"
           allowScriptAccess=\"always\"
           type=\"application/x-shockwave-flash\"
           pluginspage=\"http://www.macromedia.com/go/getflashplayer\"
           FlashVars=\"text=" text "\"
           bgcolor=\"#ffffff\"
    />
    </object>"))



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
