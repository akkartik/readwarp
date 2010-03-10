(= threadlife* 45)
(= ignore-ips* (memtable '("69.162.77.202" "69.162.127.2")))

(def nullop2(x y))

(mac run-op(op (o args (table)) (o cooks (table)))
  `(w/outstring o ((srvops* ',op) o (obj args ,args cooks ,cooks))))



(mac a-onclick(url . body)
  `(tag (a href "#" onclick ,url)
    ,@body))

(def jsquotes(s)
  (if (or (headmatch "'" s)
          (endmatch "'" s))
    s
    (+ "'" s "'")))

(def maybe-flink(f)
  (jsquotes
    (if (isa f 'fn)
      (flink f)
      f)))

(def inline(id f)
  (+ "inline('" id "', "
     maybe-flink.f
     ");"))

(def pushHistory(sname doc params)
  (+ "pushHistory('" jsesc.sname "', '" jsesc.doc "', " params ")"))

(def confirm(msg s)
  (+ "if(confirm('" msg "')){"
       s
     "}"))

(def addjsarg(l arg)
  (+ "'" l "&' + "
     arg))

(def check-with-user(msg param)
  (+ "'" param "='" " + "
     "confirm('" jsesc.msg "')"))

(mac w/jslink(attr-generator . body)
  `(tag (a ,@(eval attr-generator))
    ,@body))

(mac update-dom args
  `(let params (listtab:pair ',args)
    (list
      'href "#"
      'style (params ':style)
      'onclick (update-onclick params))))

(def update-onclick(params)
  (or (params ':onclick)
      (inline (params ':into) (params ':with))))



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
    (tag (div class "paginate")
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

(def jstag(src)
  (prn "<script src=\"" src "\"></script>"))
(def csstag(src)
  (prn "<link rel=\"stylesheet\" href=\"" src "\"></link>"))

(def header()
  (tag title (pr "ReadWarp"))
  (tag head
    (prn "<meta name=\"robots\" content=\"nofollow\"/>")
    (prn "<link rel=\"icon\" href=\"/favicon.ico\"/>")
    (csstag "main.css")

    (jstag "cookieLibrary.js")
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
    ))

(def signup-funnel(n req)
  (let funnel-name (if is-prod.req
                     "\"Signup1 Production\""
                     "\"Signup1\"")
    (tag script
      (pr "mpmetrics.track_funnel(" funnel-name ", " n ", \"" n "\");"))))

(defop-raw new-user req
  (create-user-login)
  (prn)
  (pr "new-user"))

(def create-user-login()
  (let u (stringify:unique-id)
    (cook-user u)
    (prcookie:user->cookie* u)))



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



(def clear()
  (tag (div class "clear")))

(def flash(msg)
  (tag (div class "flash") prn.msg))

(def jsesc(s)
  (subst "\\'" "'" (subst "\\\"" "\"" s)))

(def linkify(s)
  (gsub s
    (r "([^'\"'] *)(http://[^ \n'\"\\)\\]>]*)") "\\1<a target='_blank' href='\\2'>\\2</a>"
  ))

(def highlight-word(doc word keyword)
  (gsub doc
    (r (+ "(" (regexp-escape word) ")")) (+ "<a href='docs?gram=" keyword "'>\\1</a>")))

(def highlight-if-keyword(word keys)
  (if (pos (canonicalize word) keys)
    (highlight-word word word (canonicalize word))
    word))

(def highlight-keywords(doc)
  (let keys (keywords doc)
    (apply + (map [highlight-if-keyword _ keys] (partition-words doc)))))



(let server-thread* (ifcall server-thread)
  (proc start-server((o port 8080))
    (stop-server)
    (= server-thread* (new-thread "server" (fn() (asv port))))
    (push server-thread* scan-registry*))
  (proc stop-server()
    (if server-thread* (kill-thread server-thread*)))
  (def server-thread()
    server-thread*))

(def kill-handlers()
  (each (name thread) threads*
    (if (and (pos name '("handler" "timeout"))
             (~dead thread))
      (kill-thread thread))))
