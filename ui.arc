(def current-user()
  0)
(new-user:current-user)

(def current-user-read(doc)
  (read? (current-user) doc))

(def current-user-read-list()
  (read-list (current-user) (current-station-name:current-user)))

(mac current-station-preferred-feeds()
  `(preferred-feeds (current-station:current-user)))

(def next-doc(user)
  (ret ans nil
    (ero "starting next-doc")
    (= ans (pick user current-station.user))
    (ero "end next-doc")))



(mac layout-basic body
  `(tag html
    (header)
    (tag body
      (tag (div id "page")
        (tag (table width "100%")
             (tr
               (if (and (current-user) (current-station-name:current-user))
                 (tag (td id "history-container")
                    (center
                      (pr "Recently viewed"))
                    (tag (div id "history")
                      (tag (div id "history-elems")
                          (each doc (firstn 10 (current-user-read-list))
                            (render-doc-link doc)))
                      (paginate-nav "history" "/history" 10 0 10
                           (obj reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;")))))

               (tag (td id "contents-wrap")
                  (tag (div id "content")
                    ,@body))))))))

(defop || req
  (layout-basic
    (tag (div style "margin-top:15%; text-align:center")
      (tag (form action "/station")
           (tag:input id "newstationform" name "seed" size "30")
           (tag br)
           (tag:input type "submit")))))

(defop station req
  (withs (user (current-user)
          query (arg req "seed"))
    (new-station user query)
    (set-current-station-name user query)
    (w/stdout (stderr)
      (propagate-keyword-to-doc user current-station.user query))
    (layout-basic
      (render-doc-with-context next-doc.user))))

(defop docupdate req
  (ero)
  (ero "=== begin query")
  (time:mark-read (current-user) (arg req "doc") (arg req "outcome"))
  (ero "=== rendering")
  (render-doc-with-context
    (next-doc:current-user))
  (ero "=== end")
  )

(defop doc req
  (let doc (arg req "doc")
    (render-doc-with-context
      (if (blank doc)
        (next-doc:current-user)
        doc))))

(defop history req
  (paginate-bottom "history" "/history" 10
      reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
    :do
      (tag (div id "history-elems")
        (each doc (cut (current-user-read-list) start-index end-index)
          (render-doc-link doc)))))

(defop prefer req
  (if (iso "yes" (arg req "to"))
    (pushnew (doc-feed (arg req "doc")) (current-station-preferred-feeds))
    (pull (doc-feed (arg req "doc")) (current-station-preferred-feeds))))

(defop reload req
  (init-code))



(def render-doc-with-context(doc)
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons doc)
      (tag (div class "history" style "display:none")
        (render-doc-link doc))
      (tag (table class "main")
        (tr
          (tag (td class "post")
            (render-doc doc))))
      (buttons doc))
    (prn "XXX: error message, email form")))

(def render-doc(doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class "title")
      (tag (a href doc-url.doc target "_blank")
        (pr doc-title.doc)))
    (tag (div class "date")
      (aif pubdate.doc (pr render-date.it)))
    (tag div
      (whenlet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (or doc-feedtitle.doc "website")))
        (preferred-feed doc)))
    (tag p
      (pr:contents doc))))

(def render-doc-link(doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc) class (read? (current-user) doc))
      (pr "&#9632;"))
    (tag (p class "title item")
      (tag (a onclick (+ "showDoc('" doc "')") href "#" style "font-weight:bold")
        (pr doc-title.doc)))))

(def buttons(doc)
  (tag (div class "nav")
    (button doc 1 "skip" "not interesting")
    (button doc 2 "next" "kinda like")
    (button doc 3 "like" "like")
    (button doc 4 "love" "love!")
    (clear)))

(def button(doc n cls tooltip)
  (tag (a onclick (+ "pushHistory('" doc "', 'outcome='" n "')") href "#" title tooltip)
    (tag (div class (+ cls " button")))))

(def preferred-feed(doc)
  (tag (span class "icon")
    (jstogglelink (+ "save_" doc)
      (tag:img src "/saved.gif" height "24px") (+ "/prefer?doc=" doc "&to=no")
      (tag:img src "/save.gif" height "24px") (+ "/prefer?doc=" doc "&to=yes")
      (pos doc-feed.doc (current-station-preferred-feeds)))))
