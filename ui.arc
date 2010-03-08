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
                          (tag (div class "station")
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
          query (or (arg req "seed") ""))
    (ensure-station user query)
    (with-history req user query
      (render-doc-with-context user query (next-doc user query)))))

(defop delstation req
  (withs (user (current-user req)
          sname (arg req "station"))
    (wipe userinfo*.user!stations.sname)))

(def reader(req)
  (withs (user current-user.req
          query (or= userinfo*.user!all (stringify:unique-id)))
    (ensure-station user query)
    (with-history req user query
      (render-doc-with-context user query (next-doc user query)))))

(defop docupdate req
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome")
         prune-feed (is "true" (arg req "prune"))
         prune-group (is "true" (arg req "prune-group")))
    (ensure-station user sname)
    (mark-read user sname doc outcome prune-feed prune-group)
    (render-doc-with-context user sname (next-doc user sname))))

(defop doc req
  (with (user (current-user req)
         sname (arg req "station")
         doc (arg req "doc"))
    (render-doc-with-context
            user
            sname
            (if blank.doc
              (next-doc user sname)
              doc))))

(def history-panel(user sname req)
  (or= sname "")
  (ensure-station user sname)
  (let items (read-list user sname)
    (paginate req "history" (+ "/history?station=" urlencode.sname)
              25 ; sync with application.js
              len.items
        reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
      :do
        (tag (div id "history-elems")
          (each doc (cut items start-index end-index)
            (render-doc-link user sname doc))))))

(defop history req
  (history-panel current-user.req (arg req "station") req))



(def next-doc(user sname)
  (w/stdout (stderr) (pr user " " sname " => "))
  (erp:pick user userinfo*.user!stations.sname))

(def render-doc-with-context(user sname doc)
  (tag (div style "float:right")
    (feedback-form sname doc))
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons user sname doc)
      (tag (div class "history" style "display:none")
        (render-doc-link user sname doc))
      (tag (table class "main")
        (tr
          (tag (td class "post")
            (render-doc sname doc))))
      (buttons user sname doc)
      (update-title doc-title.doc))
    (do
      (deq-showlist user sname)
      (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
      (write-feedback user "" sname "" "No result found"))))

(def update-title(s)
  (if (empty s)
    (= s "Readwarp")
    (= s (+ s " - Readwarp")))
  (tag script
    (pr (+ "document.title = \"" s "\";"))))

(def render-doc(sname doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class "title")
      (tag (a href doc-url.doc target "_blank")
        (pr (check doc-title.doc ~empty "no title"))))
    (tag (div class "date")
      (aif pubdate.doc (pr render-date.it)))
    (tag div
      (iflet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (check doc-feedtitle.doc ~empty "website")))))
    (tag p
      (pr:contents doc))))

(def render-doc-link(user sname doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc)
              class (+ "outcome_icon outcome_" (read? user doc)))
      (pr "&#9632;"))
    (tag (p class "title item")
      (tag (a onclick (+ "showDoc('" jsesc.sname "', '" jsesc.doc "')") href "#" style "font-weight:bold")
        (pr (check doc-title.doc ~empty "no title"))))))

(def buttons(user sname doc)
  (tag (div class "buttons")
    (do
      (button user sname doc 1 "skip" "not interesting")
      (button user sname doc 2 "next" "more like this")
      (button user sname doc 4 "love" "more from this site"))
    (clear)))

(def button(user sname doc n cls tooltip)
  (tag:input type "button" class (+ cls " button") value tooltip
             onclick (or (mark-read-url user sname doc n)
                         (pushHistory sname doc (+ "'outcome=" n "'")))))

(def mark-read-url(user sname doc n)
  (if (is n 1)
    (if
      (and (borderline-preferred-feed user sname doc)
           (~empty doc-feedtitle.doc))
        (pushHistory sname doc
                     (addjsarg
                       (+ "outcome=" n)
                       (check-with-user
                         (+ "Should I stop showing articles from\\n"
                            "  " doc-feedtitle.doc "\\n"
                            "in this channel?")
                         "prune")))
      (awhen (borderline-unpreferred-group user sname doc)
        (pushHistory sname doc
                     (addjsarg
                       (+ "outcome=" n)
                       (check-with-user
                         (+ "Should I stop showing any articles about\\n"
                            "  " it "\\n"
                            "in this channel?")
                         "prune-group")))))))



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



(defopr logout req
  (logout-user current-user.req)
  "/")

(def feedback-form(sname doc)
  (tag (div style "margin-top:1em; text-align:right")
    (tag (a onclick "$('feedback').toggle(); return false" href "#")
      (pr "feedback")))
  (tag (form action "/feedback" method "post" id "feedback"
             style "display:none; float:right; z-index:1000; margin-top:1em; margin-left:-4000px")
    (tag:textarea name "msg" cols "25" rows "6")(br)
    (tag (div style "font-size: 75%; margin-top:0.5em")
      (pr "Your email?"))
    (tag:input name "email") (tag (i style "font-size:75%") (pr "(optional)")) (br)
    (tag:input type "hidden" name "location" value (+ "/station?seed=" sname))
    (tag:input type "hidden" name "station" value sname)
    (tag:input type "hidden" name "doc" value doc)
    (tag (div style "margin-top:0.5em")
      (do
        (tag:input type "submit" value "send" style "margin-right:1em")
        (tag:input type "button" value "cancel" onclick "$('feedback').toggle()"))))
  (clear))

(def write-feedback(user email sname doc msg)
  (w/prfile (+ "feedback/" (seconds))
    (prn "User: " user)
    (prn "Email: " email)
    (prn "Station: " sname)
    (prn "Doc: " doc)
    (prn "Feedback:")
    (prn msg)
    (prn)))

(defopr feedback req
  (write-feedback (current-user req)
                  (arg req "email")
                  (arg req "station")
                  (arg req "doc")
                  (arg req "msg"))
  (arg req "location"))

(def current-user(req)
  (ret user get-user.req
    (unless userinfo*.user ensure-user.user)))
