(mac page(user . body)
  `(tag html
    (header)
    (tag body
      (tag (div id "page")
        ,@body))))

(mac with-history(req user station . body)
  `(let user ,user
    (page user
      (nav user)
      (tag (table width "100%")
        (tr
          (tag (td id "left-panel")
            (if user
               (tag div

                  (when (and ,station
                           (~is ,station userinfo*.user!all))
                    (tag (div style "margin-bottom:1em")
                      (tag b (pr "current channel"))
                      (tag div (pr ,station))))

                  (if (or (> (len-keys userinfo*.user!stations) 2)
                          (and (is 2 (len-keys userinfo*.user!stations))
                               (is ,station userinfo*.user!all)))
                    (tag (div class "stations" style "margin-bottom:1em")
                      (tag b
                        (if (is ,station userinfo*.user!all)
                          (pr "your channels")
                          (pr "other channels")))
                      (each sname (keys userinfo*.user!stations)
                        (if (and (~is sname userinfo*.user!all)
                                 (~is sname ,station)
                                 (~blank sname))
                          (tag div
                            (tag (div style "float:right; margin-right:0.5em")
                              (tag (a href (+ "/delstation?station=" urlencode.sname)
                                      onclick "jsget(this); del(this.parentNode.parentNode); return false;")
                                (pr "x")))
                            (link sname (+ "/station?seed=" urlencode.sname)))))))

                  (tag (div style "margin-bottom:1.5em; padding-bottom:0.5em; border-bottom:1px solid #fff200")
                    (tag b (pr "new channel"))
                    (tag (form action "/station")
                         (tag:input name "seed" size "15")
                         (tag:input type "submit" value "Switch" style "margin-top:5px")))

                  ))

            (tag (div style "margin-bottom:1em")
              (tag b
                (pr "recently viewed"))
              (tag (div id "history")
                (history-panel user ,station ,req))))

          (tag (td id "contents-wrap")
             (tag (div id "content")
               ,@body)))))))

(mac logo(cls msg)
  `(tag (div class (+ "logo-button " ,stringify.cls))
      (pr ,msg)))

(= frontpage-width* "width:720px;") ; sync with main.css
(defop || req
  (if current-user.req
    (reader req)
    (front-page req)))

(def front-page(req)
  (let user current-user.req
    (page user
      (tag (div class "nav")
        (tag (div style "float:right")
          (if user
            (do
              (pr user "&nbsp;|&nbsp;")
              (link "logout" "/logout"))
            (w/link (login-page 'both "Please login to Readwarp" (list nullop2 "/"))
                    (pr "login")))
          )
        (clear))

      (tag script
        (pr "window.onload = function() {
              updateTickerContents();
              $('newstationform').focus(); };"))
      (tag (div class "logo")
        (logo fskip "RE")(logo fnext "AD")(logo flike "WA")(logo flove "RP"))
      (tag (div class "subtitle")
        (pr "Discover what you've been missing"))

      (tag (div class "frontpage" style frontpage-width*)
        (tag (form action "/station" style "width:50%;margin:auto;padding:auto")
             (pr "Tell us your favorite site or blogger") (br)
             (tag:input id "newstationform" name "seed" size "30") (br)
             (tag:input type "submit" value "Start reading" style "margin-top:5px"))

        (news-ticker)))))

(defop station req
  (withs (user (current-user req)
          query (arg req "seed"))
    (new-station user query)
    (with-history req user query
      (render-doc-with-context user query (next-doc user query)))))

(defop delstation req
  (withs (user (current-user req)
          sname (arg req "station"))
    (wipe userinfo*.user!stations.sname)))

(def reader(req)
  (withs (user current-user.req
          query (or= userinfo*.user!all (stringify:unique-id)))
    (new-station user query)
    (with-history req user query
      (render-doc-with-context user query
                               ;; XXX user's preferred feeds only manually set
                               ((if (>= (len userinfo*.user!preferred-feeds) 10)
                                  pick2
                                  pick)
                                user userinfo*.user!stations.query)))))

(defop docupdate req
  (with (user (current-user req)
         sname (arg req "station")
         doc (arg req "doc")
         outcome (arg req "outcome"))
    (mark-read user sname doc outcome)
    (handle-same-feed user sname doc outcome)
    (render-doc-with-context user sname (next-doc user sname))))

(defop doc req
  (with (user (current-user req)
         station (arg req "station")
         doc (arg req "doc"))
    (render-doc-with-context
            user
            station
            (if blank.doc
              (next-doc user station)
              doc))))

(def history-panel(user station req)
  (new-station user station)
  (let items (read-list user station)
    (paginate req "history" (+ "/history?station=" urlencode.station)
              25 ; sync with application.js
              len.items
        reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
      :do
        (tag (div id "history-elems")
          (each doc (cut items start-index end-index)
            (render-doc-link user station doc))))))

(defop history req
  (history-panel current-user.req (arg req "station") req))



(def next-doc(user sname)
  (w/stdout (stderr) (pr user " " sname " => "))
  (erp:pick user userinfo*.user!stations.sname))

(def render-doc-with-context(user station doc)
  (tag (div style "float:right")
    (feedback-form station doc))
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons station doc)
      (tag (div class "history" style "display:none")
        (render-doc-link user station doc))
      (tag (table class "main")
        (tr
          (tag (td class "post")
            (render-doc station doc))))
      (buttons station doc))
    (do
      (prn "Oops, there was an error. I've told Kartik. Please feel free to use the feedback form &rarr;")
      (write-feedback user station "" "No result found"))))

(def render-doc(station doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class "title")
      (tag (a href doc-url.doc target "_blank")
        (pr doc-title.doc)))
    (tag (div class "date")
      (aif pubdate.doc (pr render-date.it)))
    (tag div
      (iflet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (or doc-feedtitle.doc "website")))))
    (tag p
      (pr:contents doc))))

(def render-doc-link(user station doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc)
              class (+ "outcome_icon outcome_" (read? user doc)))
      (pr "&#9632;"))
    (tag (p class "title item")
      (tag (a onclick (+ "showDoc('" jsesc.station "', '" jsesc.doc "')") href "#" style "font-weight:bold")
        (pr doc-title.doc)))))

(def buttons(station doc)
  (tag (div class "buttons")
    (button station doc 1 "skip" "not interesting")
    (button station doc 2 "next" "more like this")
    (button station doc 4 "love" "more from this site")
    (clear)))

(def button(station doc n cls tooltip)
  (tag (input type "button" class (+ cls " button") value tooltip
              onclick (+ "pushHistory('" jsesc.station "', '" jsesc.doc "', 'outcome=" n "')"))))



(proc nav(user)
  (tag (div class "nav")
    (tag (div style "float:right")
      (if user
        (do
          (pr user "&nbsp;|&nbsp;")
          (link "logout" "/logout"))
        (w/link (login-page 'both "Please login to Readwarp" (list nullop2 "/"))
                (pr "login")))
      )
    (tag (div style "text-align:left")
      (link "ReadWarp" "/"))
    (clear)))



(def news-ticker()
  (tag (div style "margin-top:4em")
    (pr "Or pick a site you like"))
  (tag (div id "TICKER"
            class "ticker"
            style frontpage-width* ; must be here not in class
            onmouseover "TICKER_PAUSED=true" onmouseout "TICKER_PAUSED=false")
    (render-random-feeds))
  (tag (div id "TICKER2" style "display:none"))
  (jstag "webticker_lib.js"))

(def random-feeds()
  (ret ans nil
    (each group feedgroups*
      (if (> (len group-feeds*.group) 10)
        (repeat 2
          (aif (random-new group-feeds*.group ans
                            [feedinfo* symize._])
            (push it ans)))))))
(def render-random-feeds()
  (pr " &nbsp; &middot; &nbsp; ")
  (each title (map [(feedinfo* symize._) 'title] (random-feeds))
    (tag (a class "tickeritem" href (+ "/station?seed=" urlencode.title) rel "nofollow")
      (pr:ellipsize title 30))
    (pr " &nbsp; &middot; &nbsp; ")))
(defop tickupdate req
  (render-random-feeds))



(proc handle-same-feed(user sname doc outcome)
  (if (iso "4" outcome)
    (withs (feed doc-feed.doc
            station userinfo*.user!stations.sname)
      (if (most-recent-unread user feed)
        (push feed station!showlist)
        (flash "No more unread items in that feed")))))

(defopr logout req
  (logout-user current-user.req)
  "/")

(def feedback-form(station doc)
  (tag (div style "margin-top:1em; text-align:right")
    (tag (a onclick "$('feedback').toggle(); return false" href "#")
      (pr "feedback")))
  (tag (form action "/feedback" method "post" id "feedback"
             style "display:none; float:right; z-index:1000; margin-top:1em; margin-left:-4000px")
    (tag:textarea name "msg" cols "25" rows "6")(br)
    (tag (div style "font-size: 75%; margin-top:0.5em")
      (pr "Your email?"))
    (tag:input name "email") (tag (i style "font-size:75%") (pr "(optional)")) (br)
    (tag:input type "hidden" name "location" value (+ "/station?seed=" station))
    (tag:input type "hidden" name "station" value station)
    (tag:input type "hidden" name "doc" value doc)
    (tag (div style "margin-top:0.5em")
      (tag:input type "submit" value "send" style "margin-right:1em")
      (tag:input type "button" value "cancel" onclick "$('feedback').toggle()")))
  (clear))

(def write-feedback(user station doc msg)
  (w/prfile (+ "feedback/" (seconds))
    (prn "User: " user)
    (prn "Station: " station)
    (prn "Doc: " doc)
    (prn "Feedback:")
    (prn msg)
    (prn)))

(defopr feedback req
  (write-feedback (current-user req)
                  (arg req "station")
                  (arg req "doc")
                  (arg req "msg"))
  (arg req "location"))

(defopr reset req
  (= userinfo* (table))
  "/")

;? (defop reload req
;?   (init-code))

(def current-user(req)
  (ret user get-user.req
    (unless userinfo*.user new-user.user)))
