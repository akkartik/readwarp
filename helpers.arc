(= threadlife* 45)
(= ignore-ips* (memtable '("69.162.77.202" "69.162.127.2")))

(mac paginate(id url n max-index . block)
  (let (params body) (kwargs block '(nextcopy "next" prevcopy "prev"))
    `(withs (start-index (int2:arg req "from")
             end-index (+ start-index ,n))
        (paginate-nav ,id ,url ,n start-index end-index ,max-index ',params)
        ,@body
        (paginate-nav ,id ,url ,n start-index end-index ,max-index ',params))))

(mac paginate-bottom(id url n max-index . block)
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
    (tag (a href "#" onclick (+ "inline('" id "', '" url "?from=" (max 0 (- start-index n)) "')"))
      (pr (or (params 'prevcopy) "&larr; prev")))
    (pr (or (params 'prevcopy) "&larr; prev"))))

(def paginate-next(id url n start-index end-index max-index params)
  (if (< end-index max-index)
    (tag (a href "#" onclick (+ "inline('" id "', '" url "?from=" end-index "')"))
      (pr (or (params 'nextcopy) "next &rarr;")))
    (pr (or (params 'nextcopy) "next &rarr;"))))



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
  (csstag "main.css")
  (jstag "prototype.js")
  (jstag "effects.js")
  (jstag "controls.js")
  (jstag "dragdrop.js")
  (jstag "application.js"))

(mac jslink(i text url (o styl))
  `(tag (a class ,i onclick "toggleLink(this); return jsget(this);" href ,url style ,styl) ,text))
(def display(flag)
  (if flag
    "display:inline"
    "display:none"))
(mac jstogglelink(id text0 url0 text1 url1 which)
  `(do
    (jslink (+ ,id "_off") ,text0 ,url0 (display ,which))
    (jslink (+ ,id "_on") ,text1 ,url1 (display (not ,which)))))



(def clear()
  (tag (div style "clear:both")))

(def flash(msg)
  (tag (div class "flash") prn.msg))

(def jsesc(s)
  (subst "\\'" "'" s))

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
  (def start-server((o port 8080))
    (stop-server)
    (= server-thread* (new-thread "server" (fn() (asv port)))))
  (def stop-server()
    (if server-thread* (kill-thread server-thread*)))
  (def server-thread()
    server-thread*))
