(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(def start-funnel(req)
  (let user current-user.req
    (ensure-user user)
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
                     onclick "location.href='/'")
        )))))

(def signup-form(user)
  (tag (div class 'rwflash style "margin:0; padding:0.5em")
    (tag (span style "font-size:14px; color:#222222")
      (pr "Signup to help readwarp remember your votes."))
    (br)
    (fnform (fn(req) (create-handler req 'register
                              (list (fn(new-username ip)
                                      (swap userinfo*.user
                                            userinfo*.new-username)
                                      (signup new-username ip))
                                    "/")))
            (fn()
              (prbold "email: ")
              (input 'u "" 20)
              (tag:span style "margin-left:1em")
              (prbold "password: ")
              (tag:input name 'p type 'password size 20)
              (submit "signup"))
            t)))
