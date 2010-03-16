(mac page(user . body)
  `(tag html
    (header)
    (tag body
      (tag (div id "body")
      (tag (div id "page")
        ,@body)))))

(mac with-history(req user station . body)
  `(let user ,user
    (page user
      (nav user)
    (tag (div style "width:100%")
      (with-history-sub ,req user ,station
        ,@body)))))

(mac with-history-sub(req user station . body)
  (w/uniq s
    `(let user ,user
      (tag (div id "left-panel")
        (if user
           (tag div

              (when (and ,station
                         (~is ,station userinfo*.user!all))
                (tag (div style "margin-bottom:1em")
                  (tag b (pr "current channel"))
                  (tag div (pr ,station))))

              (when (or (> (len-keys userinfo*.user!stations) 2)
                      (and (is 2 (len-keys userinfo*.user!stations))
                           (is ,station userinfo*.user!all)))
                (tag (div class "stations" style "margin-bottom:1em; padding-bottom:1em")
                  (tag b
                    (if (is ,station userinfo*.user!all)
                      (pr "your channels")
                      (pr "other channels")))
                  (each ,s (keys userinfo*.user!stations)
                    (when (and (~is ,s userinfo*.user!all)
                             (~is ,s ,station)
                             (~blank ,s))
                      (tag (div class "station")
                        (tag (div style "float:right; margin-right:0.5em")
                          (tag (a href (+ "/delstation?station=" (urlencode ,s))
                                  onclick "jsget(this); del(this.parentNode.parentNode); return false;")
                            (tag:img src "close_x.gif")))
                        (link ,s (+ "/station?seed=" (urlencode ,s))))))))

              (tag (div style "margin-bottom:1em; padding-bottom:1em")
                (tag b (pr "new channel"))
                (tag (form action "/station")
                     (tag:input name "seed" size "15")
                     (tag (div style "color:#888888; font-size:90%;
                               margin-top:2px") (pr "type in a website or author"))
                     (tag:input type "submit" value "switch" style "margin-top:5px")))

              ))

        (tag (div style "margin-bottom:1em")
          (tag b
            (pr "recently viewed"))
          (tag (div id "history")
            (history-panel user ,station ,req))))

      (tag (div id "contents-wrap")
         (tag (div id "content")
           ,@body)))))



(defop || req
  (if (signedup? current-user.req)
    (reader req)
    (start-funnel req)))

(defop station req
  (withs (user (current-user req)
          sname (or (arg req "seed") "")
          new-sname (no userinfo*.user!stations.sname))
    (ensure-station user sname)
    (with-history req user sname
      (if new-sname
        (flash "You're now browsing in a new channel.<p>
               Votes here will not affect recommendations on other channels."))
      (render-doc-with-context user sname (next-doc user sname)))))

(defop delstation req
  (withs (user (current-user req)
          sname (arg req "station"))
    (wipe userinfo*.user!stations.sname)))

(def reader(req)
  (withs (user current-user.req
          global-sname (or= userinfo*.user!all (stringify:unique-id)))
    (ensure-station user global-sname)
    (with-history req user global-sname
      (render-doc-with-context user global-sname (next-doc user global-sname)))))

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
  (unless userinfo*.user!noob
    (flash "Welcome to your channel. Keep voting on stories as you read, and
           Readwarp will continually fine-tune its recommendations.

           <br><br>
           Readwarp is under construction. If it seems confused, try creating
           a new channel. And send us feedback!")
    (set userinfo*.user!noob))
  (if doc
    (do
      (tag (div id (+ "doc_" doc))
        (tag (div id "post-wrapper")
          (feedback-form sname doc)
          (tag (div class "history" style "display:none")
            (render-doc-link user sname doc))
          (tag (div class "post")
            (render-doc sname doc)))
        (tag div
          (buttons user sname doc)))
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
    (pr (+ "document.title = \"" jsesc.s "\";"))))

(def render-doc(sname doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class "title")
      (tag (a href doc-url.doc target "_blank")
        (pr (check doc-title.doc ~empty "no title"))))
    (tag (div class "subtitle")
      (tag (div class "date")
        (aif pubdate.doc (pr render-date.it)))
      (iflet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (check doc-feedtitle.doc ~empty "website")))))
    (tag (div class "readwarp-post-body")
      (pr:contents doc))
    (clear)))

(def render-doc-link(user sname doc)
  (tag (div id (+ "history_" doc))
    (tag (div id (+ "outcome_" doc)
              class (+ "outcome_icon outcome_" (read? user doc)))
      (pr "&#9632;"))
    (tag (p class "item")
      (tag (a onclick (+ "showDoc('" jsesc.sname "', '" jsesc.doc "')") href "#")
        (pr (check doc-title.doc ~empty "no title"))))))

(def buttons(user sname doc)
  (tag (div class "buttons")
    (do
      (button user sname doc 2 "like" "&#8593;")
      (tag p)
      (button user sname doc 1 "skip" "&#8595;"))
    (clear)))

(def button(user sname doc n cls label)
  (votebutton cls label
            (or (mark-read-url user sname doc n)
                (pushHistory sname doc (+ "'outcome=" n "'")))))

(def votebutton(cls label onclick)
  (tag (div class (+ "button " cls)
            onclick onclick)
    (tag (div style "position:relative; top:20px; font-size:22px;")
      (pr label))))

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



(proc logo-small()
  (tag (div style "text-align:left")
    (tag (a href "/" class "logo-button")
      (pr "Readwarp"))))

(proc nav(user)
  (tag (div class "nav")
    (tag (div style "float:right")
      (if signedup?.user
        (do
          (pr user "&nbsp;|&nbsp;")
          (link "logout" "/logout"))
        (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                (pr "login"))))
    (logo-small)
    (clear)))



(defopr logout req
  (logout-user current-user.req)
  "/")

(def feedback-form(sname doc)
  (tag (div id "feedback-wrapper")
    (tag (div class "feedback_link")
      (tag (a onclick "$('feedback').toggle(); return false" href "#")
        (pr "feedback")))
    (tag (form id "feedback" action "/feedback" method "post" style
               "display:none")
      (tag:textarea name "msg" cols "25" rows "6" style "text-align:left")(br)
      (tag (div style "font-size: 75%; margin-top:0.5em; text-align:left")
        (pr "Your email?"))
      (tag:input name "email") (tag (i style "font-size:75%") (pr "(optional)")) (br)
      (tag:input type "hidden" name "location" value (+ "/station?seed=" sname))
      (tag:input type "hidden" name "station" value sname)
      (tag:input type "hidden" name "doc" value doc)
      (tag (div style "margin-top:0.5em; text-align:left")
        (do
          (tag:input type "submit" value "send" style "margin-right:1em")
          (tag:input type "button" value "cancel" onclick "$('feedback').toggle()"))))
    (clear)))

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

(def signup(user ip)
  (ensure-user user)
  (or= userinfo*.user!all (stringify:unique-id))
  (ensure-station user userinfo*.user!all)
  (unless userinfo*.user!signedup
    (set userinfo*.user!signedup)
    (= userinfo*.user!created (seconds))))

(def signedup?(user)
  (and userinfo*.user userinfo*.user!signedup))

(def current-user(req)
  (ret user get-user.req
    (unless userinfo*.user ensure-user.user)))
