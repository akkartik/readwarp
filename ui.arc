(def current-user()
  0)
(new-user:current-user)

(def current-station-name(user)
  userinfo*.user!current-station)

(def current-station(user)
  (userinfo*.user!stations current-station-name.user))

(def current-user-read(doc)
  (read? (current-user) doc))

(def current-user-read-list()
  (read-list (current-user) (current-station-name:current-user)))

(def next-doc(user sname)
  (pick user (if sname
               userinfo*.user!stations.sname
               current-station.user)))

(def prn-stats(msg)
  (erp msg (w/table ans
    (each (name thread) threads*
      (unless dead.thread
        (++ (ans name 0)))))))

(def kill-handlers()
  (each (name thread) threads*
    (if (and (pos name '("handler" "timeout"))
             (~dead thread))
      (kill-thread thread))))



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
                            (render-doc-link (current-station-name:current-user) doc)))
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

    (tag (div style "margin-top:4em; font-size:16px")
      (tag (form action "/station" style "width:50%;margin:auto;padding:auto")
           (pr "Tell us your favorite site or blogger.") (br)
           (tag:input id "newstationform" name "seed" size "30") (br)
           (tag:input type "submit" value "Start reading"))

      (news-ticker))))

(defop station req
  (withs (user (current-user)
          query (arg req "seed"))
    (new-station user query)
    (= userinfo*.user!current-station query)
    (layout-basic
      (render-doc-with-context query (next-doc user query)))))

(defop docupdate req
  (mark-read (current-user) (arg req "station") (arg req "doc") (arg req "outcome"))
  (render-doc-with-context
    (arg req "station")
    (next-doc (current-user) (arg req "station"))))

(defop doc req
  (let doc (arg req "doc")
    (render-doc-with-context
      (arg req "station")
      (if (blank doc)
        (next-doc (current-user) (arg req "station"))
        doc))))

(defop history req
  (paginate-bottom "history" "/history" 10
      reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
    :do
      (tag (div id "history-elems")
        (each doc (cut (current-user-read-list) start-index end-index)
          (render-doc-link (current-station-name:current-user) doc)))))

(defop prefer req
  (with (doc (arg req "doc")
         dir (arg req "to")
         station (current-station:current-user))
    (preferred-feed-manual-set station doc (iso "yes" dir))))



(def feedback-form(station doc)
  (tag (a onclick "$('feedback').toggle(); return false" href "#" style "margin-right:1em")
    (pr "feedback"))
  (tag (form action "/feedback" method "post" id "feedback" style "display:none; background:#888; padding:0.5em; position:absolute; left:85%; top:5%; z-index:1; text-align:right")
    (tag:textarea name "msg" style "width:100%")(br)
    (tag:input type "hidden" name "location" value (+ "/station?seed=" station))
    (tag:input type "hidden" name "station" value station)
    (tag:input type "hidden" name "doc" value doc)
    (tag:input type "submit" value "send")))

(defopr feedback req
  (w/prfile (+ "feedback/" (seconds))
    (prn "Station: " (arg req "station"))
    (prn "Doc: " (arg req "doc"))
    (prn)
    (prn "Feedback:")
    (prn (arg req "msg")))
  (arg req "location"))

(def news-ticker()
  (tag (div style "margin-top:4em")
    (pr "Or pick a site you like"))
  (tag (div id "TICKER"
            class "ticker"
            style "width:520px" ; must be here not in class
            onmouseover "TICKER_PAUSED=true" onmouseout "TICKER_PAUSED=false")
    (render-random-feeds))
  (tag (div id "TICKER2" style "display:none"))
  (jstag "webticker_lib.js"))

(def random-feeds()
  (ret ans nil
    (each group feed-groups*
      (if (> (len group-feeds*.group) 10)
        (repeat 2
          (aif (random-new group-feeds*.group ans
                            [feedinfo* symize._])
            (push it ans)))))))
(def render-random-feeds()
  (pr " &middot; ")
  (each title (map [(feedinfo* symize._) 'title] (random-feeds))
    (tag (a class "tickeritem" href (+ "/station?seed=" urlencode.title))
      (pr:ellipsize title 15))
    (pr " &middot; ")))
(defop tickupdate req
  (render-random-feeds))

(defopr reset req
  (= userinfo* (table))
  (new-user:current-user)
  "/")

(defop reload req
  (init-code))



(def render-doc-with-context(station doc)
  (tag (div style "float:right")
    (feedback-form station doc))
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons station doc)
      (tag (div class "history" style "display:none")
        (render-doc-link station doc))
      (tag (table class "main")
        (tr
          (tag (td class "post")
            (render-doc station doc))))
      (buttons station doc))
    (prn "XXX: error message, email form")))

(def render-doc(station doc)
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
        (render-preferred-feed station doc)))
    (tag p
      (pr:contents doc))))

(def render-doc-link(station doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc)
              class (+ "outcome_icon outcome_" (read? (current-user) doc)))
      (pr "&#9632;"))
    (tag (p class "title item")
      (tag (a onclick (+ "showDoc('" jsesc.station "', '" jsesc.doc "')") href "#" style "font-weight:bold")
        (pr doc-title.doc)))))

(def buttons(station doc)
  (tag (div class "nav")
    (button station doc 1 "skip" "not interesting")
    (button station doc 2 "next" "kinda like")
    (button station doc 3 "like" "like")
    (button station doc 4 "love" "love!")
    (clear)))

(def button(station doc n cls tooltip)
  (tag (a onclick (+ "pushHistory('" jsesc.station "', '" jsesc.doc "', 'outcome=" n "')") href "#" title tooltip)
    (tag (div class (+ cls " button")))))

(def render-preferred-feed(sname doc)
  (tag (span class "icon")
    (jstogglelink (+ "save_" doc)
      (tag:img src "/saved.gif" height "24px") (+ "/prefer?doc=" doc "&to=no")
      (tag:img src "/save.gif" height "24px") (+ "/prefer?doc=" doc "&to=yes")
      (let user (current-user)
        (preferred-feed? userinfo*.user!stations.sname doc)))))
