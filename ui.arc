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
      (with-history-sub ,req user ,station
        ,@body))))

(mac with-history-sub(req user station . body)
  `(let user ,user
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
                              (tag:img src "close_x.gif")))
                          (link sname (+ "/station?seed=" urlencode.sname)))))))

                (tag (div style "margin-bottom:1.5em; padding-bottom:0.5em; border-bottom:1px solid #cccccc")
                  (tag b (pr "new channel"))
                  (tag (form action "/station")
                       (tag:input name "seed" size "15")
                       (tag (div style "color:#aaa; font-size:90%;
                                 margin-top:2px") (pr "type in a website or author"))
                       (tag:input type "submit" value "switch" style "margin-top:5px")))

                ))

          (tag (div style "margin-bottom:1em")
            (tag b
              (pr "recently viewed"))
            (tag (div id "history")
              (history-panel user ,station ,req))))

        (tag (td id "contents-wrap")
           (tag (div id "content")
             ,@body))))))



(defop || req
  (if (signedup? current-user.req)
    (reader req)
    (start-funnel req)))

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
  (unless userinfo*.user!noob
    (flash "Welcome to your channel. Keep voting on stories as you read, and
           Readwarp will continually fine-tune its recommendations.

           <br><br>
           Readwarp is under construction. If it seems confused, try creating
           a new channel. And send us feedback!")
    (set userinfo*.user!noob))
  (tag (div style "float:right")
    (feedback-form sname doc))
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons user sname doc)
      (tag (div class "history" style "display:none")
        (render-doc-link user sname doc))
      (tag (div class "post")
        (render-doc sname doc))
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
    (pr (+ "document.title = \"" jsesc.s "\";"))))

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
      (pr:contents doc))
    (clear)))

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
      (button user sname doc 2 "like" "&#x21e7;")
      (button user sname doc 1 "skip" "&#x21e9;"))
    (clear)))

(def button(user sname doc n cls label)
  (votebutton cls label
            (or (mark-read-url user sname doc n)
                (pushHistory sname doc (+ "'outcome=" n "'")))))

(def votebutton(cls label onclick)
  (pr "<input type=\"button\" class=\"button " cls "\" value=\"" label "\" "
      "onclick=\"" onclick "\"/>"))

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



(mac logo(msg)
  `(tag (div class "logo-button")
      (pr ,msg)))

(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(init funnel-length* (+ 1 funnel-signup-stage*))
(def start-funnel(req)
  (let user current-user.req
    (page user
      (tag (div class "nav")
        (tag (div style "float:right")
          (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                  (pr "login")))
        (clear))

      (tag (div class "frontpage")

        (tag (div class "logo")
          (logo "Readwarp"))
        (tag (div style "font-style:italic; margin-top:1em")
          (pr "&ldquo;What do I read next?&rdquo;"))

        (tag (div style "margin-top:1.5em")
          (tag div
            (pr "Readwarp learns your tastes &mdash; <i>fast</i>."))
          (tag (div style "margin-top: 0.2em")
            (pr "Just vote on 6 stories to get started."))
          (tag:input type "button" value "Start reading" style "margin-top:1.5em"
                     onclick "location.href='/begin'")

          (signup-funnel-analytics 1 req)

        )))))

(init signup-groups* '(News Technology Magazine Economics
                       Sports Fashion Travel Comics))
(when (len< signup-groups* quiz-length*)
  (erp "Too few signup groups")
  (really-quit))

(defop begin req
  (let user current-user.req
    (or= userinfo*.user!signup-stage 2)
    (page user
      (tag (div style "width:600px; margin:auto")
        (tag (div class "nav")
          (logo-small))

        (unless userinfo*.user!all
          (= userinfo*.user!all (stringify:unique-id)))

        (let query userinfo*.user!all
          (unless userinfo*.user!stations.query
            (ensure-station2 user query)
            (= userinfo*.user!initial-stations
               (erp:shuffle:map stringify signup-groups*))
            (= userinfo*.user!stations.query!groups (table)))

          (tag (div id "content" style "padding-left:0")
            (if (is 2 userinfo*.user!signup-stage)
              (flash:+ "Ok! We'll now gauge your tastes using " quiz-length*
                       " stories.<br>
                       Vote for the stories or sites that you like."))
            (next-stage user query req)))))))

(proc ensure-station2(user sname)
  (ensure-user user)
  (when (no userinfo*.user!stations.sname)
    (= userinfo*.user!stations.sname (table))
    (let station userinfo*.user!stations.sname
      (= station!name sname station!preferred (table) station!unpreferred (table))
      (= station!created (seconds))
      (= station!showlist (queue))
      (= station!last-showlist (queue)))))

(proc next-stage(user query req)
  (let stage userinfo*.user!signup-stage
    (signup-funnel-analytics stage req)
    (unless is-prod.req
      (tag (div class "debug") (pr:+ "Stage " stage)))
    (erp user ": stage " stage)
    (if (>= stage funnel-signup-stage*)
      (signup-form user query req)
      (render-doc-with-context2 user query next-doc2.user))))

(def next-doc2(user)
  (withs (group (car userinfo*.user!initial-stations)
          feeds (group-feeds* group)
          feed  (findg randpos.feeds
                       [most-recent-unread user _]))
    (w/stdout (stderr) (pr user " " group " => "))
    (erp:most-recent-unread user feed)))

(mac modal(show . body)
  `(do
    (csstag "modal.css")
    (tag (div id "modal" style ,show)
      (tag:div class "overlay-decorator" style ,show)
      (tag (div class "overlay-wrap")
        (tag (div class "overlay")
          (tag:div class "dialog-decorator")
          (tag (div class "dialog-wrap")
            (tag (div id "dialog" class "dialog")
              ,@body)))))))

(mac with-history-sub2(req user station . body)
  `(let user ,user
    (tag (table style "width:960px; overflow:hidden; font-size:80%")
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
                              (tag:img src "close_x.gif")))
                          (link sname (+ "/station?seed=" urlencode.sname)))))))

                (tag (div style "margin-bottom:1.5em; padding-bottom:0.5em; border-bottom:1px solid #cccccc")
                  (tag b (pr "new channel"))
                  (tag (form action "/station")
                       (tag:input name "seed" size "15")
                       (tag (div style "color:#aaa; font-size:90%;
                                 margin-top:2px") (pr "type in a website or author"))
                       (tag:input type "submit" value "switch" style "margin-top:5px")))

                ))

          (tag (div style "margin-bottom:1em")
            (tag b
              (pr "recently viewed"))
            (tag (div id "history")
              (history-panel user ,station ,req))))

        (tag (td id "contents-wrap")
           (tag (div id "content")
             ,@body))))))

(def signup-form(user query req)
  ; example rendering
  (with-history-sub2 req user query
    (render-doc-with-context user query (next-doc user query)))
  (= userinfo*.user!stations.query!showlist (queue))
  (start-rebuilding-showlist user userinfo*.user!stations.query)

  (modal "display:block"
    (tag (div style "background:#fff; padding:1em; margin-bottom:100%")
      (prbold "Thank you!")
      (br)
      (tag (span style "font-size:14px; color:#888888")
        (pr "Please claim your personal reading channel."))
      (br2)
      (fnform (fn(req) (create-handler req 'register
                                (list (fn(new-username ip)
                                        (swap userinfo*.user
                                              userinfo*.new-username)
                                        (signup new-username ip))
                                      "/")))
              (fn() (pwfields "signup"))
              t))))

(def render-doc-with-context2(user sname doc)
  (tag (div style "float:right")
    (feedback-form sname doc))
  (if doc
    (tag (div id (+ "doc_" doc))
      (buttons2 user sname doc)
      (tag (div class "post")
        (render-doc sname doc))
      (buttons2 user sname doc)
      (update-title doc-title.doc))
    (do
      (deq-showlist user sname)
      (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
      (write-feedback user "" sname "" "No result found"))))

(def buttons2(user sname doc)
  (tag (div class "buttons")
    (do
      (button2 user sname doc 2 "like" "&#x21e7;")
      (button2 user sname doc 1 "skip" "&#x21e9;"))
    (clear)))

(def button2(user sname doc n cls label)
  (votebutton cls label
            (inline "content"
                    (+ "/docupdate2?doc=" urlencode.doc
                       "&station=" urlencode.sname "&outcome=" n))))

(defop docupdate2 req
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome"))
    (nopr
      (ensure-station user sname)
      (mark-read2 user sname doc outcome)
      (++ userinfo*.user!signup-stage))
    (next-stage user sname req)))

(proc mark-read2(user sname doc outcome)
  (with (station  userinfo*.user!stations.sname
         feed     doc-feed.doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)

    (or= station!last-showlist (queue))
    (enq-limit feed
          station!last-showlist
          history-size*)

    (or= station!preferred (table))
    (when (is outcome "2")
      (each g (erp:signup-group-mapping*:car userinfo*.user!initial-stations)
        (or= userinfo*.user!stations.sname!groups.g (backoff doc 2))))
    (pop userinfo*.user!initial-stations)))

(init signup-group-mapping*
  (obj
    "News" '("News" "Politics" "Economics" "Technology")
    "Technology" '("Technology" "Programming" "Venture" "Games" "Science" "Biology")
    "Magazine" '("Magazine" "Comics" "Design" "Movies" "Books" "Music" "Auto" "Art" "Travel")
    "Economics" '("News" "Politics" "Economics" "Technology")
    "Sports" '("Sports" "Cricket")
    "Fashion" '("Fashion" "Glamor" "Food" "Health")
    "Travel" '("Magazine" "Comics" "Design" "Movies" "Books" "Music" "Auto" "Art" "Travel")
    "Comics" '("Magazine" "Games" "Comics")))



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
