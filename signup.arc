(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(def start-funnel(req)
  (let user current-user.req
    (page req
      (tag (div style "background:white; min-height:95%;" class "rwrounded-bottom rwshadow")
        (tag (div id 'rwnav)
          (tag (div style "float:right")
            (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                    (pr "login")))
          (clear))

        (tag (div id 'rwfrontpage)

          (tag (div class 'rwlogo)
            (tag:img src "readwarp.png" width "200px"))
          (tag (div style "font-style:italic; font-size:80%; margin-top:0.5em")
            (pr "What do I read next?"))

          (tag (div style "margin-left:auto; margin-right:auto; width:19em")
            (tag (ul style "margin-top:1em; text-align:left;")
              (tag li
                (pr "Read all your favorite sites in one place."))
              (tag li
                (pr "Readwarp learns your tastes <i>fast</i>."))
              (tag li
                (pr "Discover sites you'll love."))))

          (tag:input type "button" id "rwstart-funnel" value "Start reading now"
                     onclick "location.href='/begin'")
        )))))

(defop begin req
  (let user current-user.req
    (ensure-user user)
    (or= userinfo*.user!signup-stage 2)
    (page req
      (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
        (logo-small))
      (tag:div class 'rwsep)

      (tag (div style "width:100%")
        (tag (div id 'rwcontents-wrap)
          (tag (div id 'rwcontent)
            (next-stage user req)))))))

(proc next-stage(user req (o flashfn))
  (let funnel-stage userinfo*.user!signup-stage
    (erp user ": stage " funnel-stage)
    (doc-panel user next-doc.user
      (fn()
        (when (>= userinfo*.user!signup-stage funnel-signup-stage*)
          (signup-form user))
        (when (is 2 userinfo*.user!signup-stage)
          (flash:+ "Click on the buttons to like or dislike each story and
                   move to the next one.
                   <p>
                   To see specific kinds of stories, type in a site on the
                   left."))
        (when flashfn (flashfn))))))

(def signup-form(user)
  (tag (div class 'rwflash style "margin:0; padding:0.5em")
    (tag (span style "font-size:14px; color:#222222")
      (prbold "Please sign up to save your votes."))
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

(def signup-doc-panel(user req (o flashfn))
  (ensure-user user)
  (or= userinfo*.user!signup-stage 0)
  (++ userinfo*.user!signup-stage)
  (next-stage user req flashfn))
