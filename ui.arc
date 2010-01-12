(= threadlife* 90)

(def current-user()
  0)
(new-user:current-user)

(def current-user-read(doc)
  (read? (current-user) doc))

(def current-user-read-list()
  (read-list (current-user) (current-station-name:current-user)))

(def next-doc(user)
  (pick user current-station.user))



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
  (new-station (current-user) (arg req "seed"))
  (set-current-station-name (current-user) (arg req "seed"))
  (layout-basic
    (render-doc-with-context
      (next-doc:current-user))))

(defop docupdate req
  (mark-read (current-user) (arg req "doc") (arg req "outcome"))
  (render-doc-with-context
    (next-doc:current-user)))

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

(defop reload req
  (init-code))



(def render-doc(doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class "title")
      (tag (a href doc-url.doc target "_blank")
        (pr doc-title.doc)))
    (tag div
      (iflet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (or doc-feedtitle.doc "website")))))
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
    (next-button doc)
    (read-button doc)
    (skip-button doc)
    (all-read-button doc)
    (clear)))

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

(def read-button(doc)
  (tag (a onclick (+ "pushHistory('" doc "', 'outcome=read')") href (+ "#" doc) style "text-decoration:none")
    (tag (div class "read-button")
      (pr "&uarr;"))))

(def next-button (doc)
  (tag (a onclick (+ "pushHistory('" doc "', 'outcome=next')") href (+ "#" doc) style "text-decoration:none")
    (tag (div class "next-button")
      (pr "Next"))))

(def skip-button(doc)
  (tag (a onclick (+ "pushHistory('" doc "', 'outcome=skip')") href (+ "#" doc) style "text-decoration:none")
    (tag (div class "skip-button")
      (pr "&darr;"))))

(def all-read-button(doc)
  (tag (a onclick (+ "pushHistory('" doc "', 'all=1&outcome=done')") href (+ "#" doc) style "text-decoration:none")
    (tag (div class "allr-button")
      (pr "Feed read"))))
