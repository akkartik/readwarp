(mac logo(msg)
  `(tag (div class 'rwlogo-button)
      (pr ,msg)))

(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(def start-funnel(req)
  (let user current-user.req
    (init-abtests user)
    (page
      (tag (div style "background:white; min-height:95%;" class "rounded-bottom white-shadow")
        (tag (div id 'rwnav)
          (tag (div style "float:right")
            (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                    (pr "login")))
          (clear))

        (tag (div id 'rwfrontpage)

          (tag (div class 'rwlogo)
            (logo "Readwarp"))
          (tag (div style "font-style:italic; margin-top:1em")
            (pr "&ldquo;What do I read next?&rdquo;"))

          (tag (div style "margin-top:1.5em")
            (tag div
              (pr "Readwarp learns your tastes &mdash; <i>fast</i>."))
            (tag (div style "margin-top: 0.2em")
              (pr "Vote on just 6 stories to get started."))
            (tag:input type "button" id "start-funnel" value "Start reading" style "margin-top:1.5em"
                       onclick "location.href='/begin'")

            (signup-funnel-analytics is-prod.req 1 user)

        ))))))

(defop begin req
  (withs (user current-user.req
          global-sname (or= userinfo*.user!all (stringify:unique-id)))
    (ensure-station user global-sname)
    (or= userinfo*.user!signup-stage 2)
    (page
      (tag (div id 'rwnav class "rounded-bottom white-shadow")
        (logo-small))
      (tag:div class 'rwsep)

      (let sname userinfo*.user!all
        (tag (div style "width:100%")
          (tag (div id 'rwcontents-wrap)
            (tag (div id 'rwcontent)
              (next-stage user sname req))))))))

(proc next-stage(user query req)
  (let funnel-stage userinfo*.user!signup-stage
    (signup-funnel-analytics is-prod.req funnel-stage user)
    (erp user ": stage " funnel-stage)
    (doc-panel2 user query (next-doc user userinfo*.user!all))))

(def signup-form(user)
  (tag (div style "text-align:left; background:#915c69; padding:0.5em")
    (tag (span style "font-size:14px; color:#222222")
      (prbold "Please save your preferences."))
    (br)
    (fnform (fn(req) (create-handler req 'register
                              (list (fn(new-username ip)
                                      (swap userinfo*.user
                                            userinfo*.new-username)
                                      (signup new-username ip))
                                    "/")))
            (fn()
              (pr "email: ")
              (input 'u "" 20)
              (tag:span style "margin-left:1em")
              (pr "password: ")
              (tag:input name 'p type 'password size 20)
              (submit "signup"))
            t)))

(def progress-bar(user)
  (tag div
    (tag (div style "float:left;margin-left:1em; margin-top:1em")
      (pr "Progress: "))
    (tag (div class 'rwprogress style "width:8em; margin-top:1em")
      (tag (div class 'rwprogress_filled
                style (+ "width:"
                         (int:* funnel-signup-stage*
                                (/ userinfo*.user!signup-stage
                                   funnel-signup-stage*))
                         "em;"))))
    (clear)))

(proc init-abtests(user)
  (init-funnel-property user "signup" "false"))

(def doc-panel2(user sname doc)
  (if doc
    (do
      (tag div
        (tag div
          (buttons2 user sname doc))
        (tag (div id 'rwpost-wrapper class "rounded white-shadow")
          (if (>= userinfo*.user!signup-stage funnel-signup-stage*)
            (signup-form user)
            (progress-bar user))
          (tag (div style "width:100%; margin-right:1em")
                (when (is 2 userinfo*.user!signup-stage)
                  (flash:+ "Ok! Click on <img src='save-button-384cff.png'
                           style='vertical-align:bottom' height='28px'> to like a story,
                           and on <img src='thumbs-down-button2.png' height='28px'
                           style='vertical-align:bottom;'> to dislike."))
            (tag (div id 'rwpost)
              (feedback-form user sname doc)
              (render-doc user doc))))
        (clear))
      (update-title doc-title.doc))
    (do
      (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
      (write-feedback user "" sname "" "No result found"))))

(def buttons2(user sname doc)
  (tag (div id 'rwbuttons class "rounded-left button-shadow")
    (tag (div class "rwbutton rwlike"
              onclick (inline "rwcontent"
                              (+ "/docupdate2?doc=" urlencode.doc
                                 "&station=" urlencode.sname
                                 "&outcome=" 2)))
      (tag (div style "position:relative; top:25px; font-size:16px;")
        (pr "next")))
    (tag p)
    (tag (div class 'rwbutton
              onclick (inline "rwcontent"
                              (+ "/docupdate2?doc=" urlencode.doc
                                 "&station=" urlencode.sname
                                 "&outcome=" vote-bookmark*)))
      (tag:img src "save-button-384cff.png" height "60px"))
    (tag (div class 'rwbutton onclick
            (inline "rwcontent"
                  (maybe-prompt user sname doc
                    (+ "/docupdate2?doc=" urlencode.doc
                       "&station=" urlencode.sname "&outcome=" 1))))
      (tag:img src "thumbs-down-button2.png" height "64px"))
    (clear)))

(defop docupdate2 req
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome")
         prune-feed (is "true" (arg req "prune"))
         group (arg req "group")
         prune-group (is "true" (arg req "prune-group")))
    (ensure-station user sname)
    (mark-read user sname doc outcome prune-feed group prune-group)
    (++ userinfo*.user!signup-stage)
    (next-stage user sname req)))
