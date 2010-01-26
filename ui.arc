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

(mac logo(cls msg)
  `(tag (div class (+ "logo-button " ,stringify.cls))
      (pr ,msg)))

(defop || req
  (header)
  (tag body
    (tag (div class "logo" style "margin-top:5em")
      (logo fskip "RE")(logo fnext "AD")(logo flike "WA")(logo flove "RP"))
    (tag (div class "subtitle")
      (pr "Discover what you've been missing"))

    (tag (div style "margin-top:5%; font-size:16px")
      (tag (form action "/station" style "width:50%;margin:auto;padding:auto")
           (pr "Tell us your favorite site or blogger.") (br)
           (tag:input id "newstationform" name "seed" size "30") (br)
           (tag:input type "submit" value "Start reading")))

    (news-ticker)))

(def news-ticker()
  (tag (div id "TICKER"
            class "ticker"
            style "width:520px" ; must be here not in class
            onmouseover "TICKER_PAUSED=true" onmouseout "TICKER_PAUSED=false")
    (pr "abc"))
  (tag (div id "TICKER2" style "display:none"))
  (jstag "webticker_lib.js"))

(= performance-vector ($:make-vector 10))

(def prn-stats()
  ($:vector-set-performance-stats! _performance-vector)
  (erp performance-vector))

(defop station req
  (withs (user (current-user)
          query (arg req "seed"))
    (new-station user query)
    (set-current-station-name user query)
    (layout-basic
      (render-doc-with-context next-doc.user))))

(defop docupdate req
  (erp "docupdate")
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

(defop prefer req
  (with (doc (arg req "doc")
         dir (arg req "to")
         station (current-station:current-user))
    (preferred-feed-manual-set station doc (iso "yes" dir))))

(defopr reset req
  (= userinfo* (table))
  (new-user:current-user)
  "/")

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
        (render-preferred-feed doc)))
    (tag p
      (pr:contents doc))))

(def render-doc-link(doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc)
              class (+ "outcome_icon outcome_" (read? (current-user) doc)))
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
  (tag (a onclick (+ "pushHistory('" doc "', 'outcome=" n "')") href "#" title tooltip)
    (tag (div class (+ cls " button")))))

(def render-preferred-feed(doc)
  (tag (span class "icon")
    (jstogglelink (+ "save_" doc)
      (tag:img src "/saved.gif" height "24px") (+ "/prefer?doc=" doc "&to=no")
      (tag:img src "/save.gif" height "24px") (+ "/prefer?doc=" doc "&to=yes")
      (preferred-feed? (current-station:current-user) doc))))
