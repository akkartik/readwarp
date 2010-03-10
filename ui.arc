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
      (button user sname doc 1 "skip" "thumbs down")
      (button user sname doc 2 "next" "thumbs up"))
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
      (if signedup?.user
        (do
          (pr user "&nbsp;|&nbsp;")
          (link "logout" "/logout"))
        (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                (pr "login")))
      )
    (tag (div style "text-align:left")
      (tag (a href "/" class "logo-button fskip")
        (pr "ReadWarp")))
    (clear)))



(mac logo(cls msg)
  `(tag (div class (+ "logo-button " ,stringify.cls))
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
          (logo fskip "READWARP"))
        (tag (div style "font-style:italic; margin-top:1em")
          (pr "&ldquo;What do I read next?&rdquo;"))

        (tag (div style "margin-top:1.5em")
          (tag div
            (pr "Readwarp learns your tastes &mdash; <i>fast</i>."))
          (tag (div style "margin-top: 0.2em")
            (pr "Just vote on 6 stories to get started."))
          (tag:input type "button" value "Start reading" style "margin-top:1.5em"
                     onclick "location.href='/begin'")

          (signup-funnel 1 req)

        )))))

(def is-prod(req)
  (~is "127.0.0.1" req!ip))

(defop begin req
  (let user current-user.req
    (or= userinfo*.user!signup-stage 2)
    (page user
      (tag (div style "width:600px; margin:auto")
        (tag (div class "nav")
          (tag (div style "text-align:left")
            (tag (a class "logo-button fskip")
              (pr "ReadWarp"))))

        (let query (or= userinfo*.user!all (stringify:unique-id))
          (nopr:ensure-station user query)
          (tag (div id "content")
            (next-stage user query req)))))))

(proc next-stage(user query req)
  (signup-funnel userinfo*.user!signup-stage req)
  (flash:+ "Stage " userinfo*.user!signup-stage)
  (if (is userinfo*.user!signup-stage funnel-signup-stage*)
    (signup-form user query)
    (render-doc-with-context2 user query (next-doc user query))))

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
              ,@body))))))

(def signup-form(user query)
  (pr "current-username: " user)
  (modal "display:block"
    (tag (div style "background:#fff; padding:1em; margin-bottom:100%")
      (prbold "Save your responses")
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
      (button2 user sname doc 1 "skip" "thumbs down")
      (button2 user sname doc 2 "next" "thumbs up"))
    (clear)))

(def button2(user sname doc n cls tooltip)
  (tag:input type "button" class (+ cls " button") value tooltip
             onclick (inline "content"
                             (+ "/docupdate2?doc=" urlencode.doc
                                "&station=" urlencode.sname "&outcome=" n))))

(defop docupdate2 req
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome")
         prune-feed (is "true" (arg req "prune"))
         prune-group (is "true" (arg req "prune-group")))
    (nopr
      (ensure-station user sname)
      (mark-read user sname doc outcome prune-feed prune-group)
      (++ userinfo*.user!signup-stage))
    (next-stage user sname req)))



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
