(mac logo(msg)
  `(tag (div class 'rwlogo-button)
      (pr ,msg)))

(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(def start-funnel(req)
  (let user current-user.req
    (init-abtests user)
    (page req
      (tag (div style "background:white; min-height:95%;" class "rwrounded-bottom rwshadow")
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
    (page req
      (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
        (logo-small))
      (tag:div class 'rwsep)

      (let sname userinfo*.user!all
        (tag (div style "width:100%")
          (tag (div id 'rwright-panel)
            (history-panel user sname req))
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
      (prbold "Please sign up to save your preferences &mdash; and to unlock a
              few more features."))
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
  )

(def doc-panel2(user sname doc)
  (if doc
    (do
      (tag (div id (+ "doc_" doc))
        (tag div
          (buttons user sname doc))
        (tag (div id 'rwpost-wrapper class "rwrounded rwshadow")
          (if (>= userinfo*.user!signup-stage funnel-signup-stage*)
            (signup-form user)
            (progress-bar user))
          (tag div
            (when (is 2 userinfo*.user!signup-stage)
              (flash:+ "Ok! Click on the buttons on the left to like or
                       dislike each story and move to the next one."))
            (unless userinfo*.user!read.doc
              (tag (div class 'rwhistory-link style "display:none")
                (render-doc-link user sname doc)))
            (tag (div id 'rwpost)
              (feedback-form user sname doc)
              (render-doc user doc))))
        (clear))
      (update-title doc-title.doc))
    (do
      (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
      (write-feedback user "" sname "" "No result found"))))

(def signup-doc-panel(user sname req)
  (++ userinfo*.user!signup-stage)
  (next-stage user sname req))
