(mac logo(msg)
  `(tag (div class 'rwlogo-button)
      (pr ,msg)))

(init quiz-length* 6)
(init funnel-signup-stage* (+ 2 quiz-length*))
(def start-funnel(req)
  (let user current-user.req
    (start-rebuilding-signup-showlist user 'sleep)
    (page user
      (tag (div class 'rwnav)
        (tag (div style "float:right")
          (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                  (pr "login")))
        (clear))

      (tag (div class 'rwfrontpage)

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

          (signup-funnel-analytics 1 req)

        )))))

(init signup-groups* '(News Technology Magazine Economics
                       Sports Fashion Travel Comics))
(when (len< signup-groups* quiz-length*)
  (erp "Too few signup groups")
  (really-quit))

(defop begin req
  (let user current-user.req
    (start-rebuilding-signup-showlist user nil)
    (or= userinfo*.user!signup-stage 2)
    (tag html
      (header
        (csstag "modal.css"))
      (tag body
        (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          (tag (div class 'rwnav)
            (logo-small))

          (let sname userinfo*.user!all
            (tag (div style "width:100%")
              (tag (div style "float:left; height:1em; width:175px"))
              (tag (div id 'rwcontents-wrap)
                (tag (div id 'rwcontent)
                    (next-stage user sname req)))))))))))

(proc ensure-station2(user sname)
  (ensure-user user)
  (when (no userinfo*.user!stations.sname)
    (inittab userinfo*.user!stations.sname
             'name sname
             'preferred (table)
             'unpreferred (table)
             'created (seconds)
             'groups (table))))

(proc next-stage(user query req)
  (let stage userinfo*.user!signup-stage
    (signup-funnel-analytics stage req)
    (erp user ": stage " stage)
    (if (>= stage funnel-signup-stage*)
      (signup-form user query req)
      (render-doc-with-context2 user query next-doc2.user))))

(def next-doc2(user)
  (erp "waiting")
  (wait:< 0 (qlen userinfo*.user!signup-showlist))
  (w/stdout (stderr) (pr user " => "))
  (erp:pick2 user))

(def pick2(user)
  (car:qlist userinfo*.user!signup-showlist))

(proc start-rebuilding-signup-showlist(user pause)
  (unless userinfo*.user!signup-showlist-thread
    (set userinfo*.user!signup-showlist-thread)
    (thread "signup-showlist"
      (when pause (sleep 1))
      (w/stdout (stderr)
        (rebuild-signup-showlist user)))))

(proc rebuild-signup-showlist(user)
  (unless userinfo*.user!all
    (= userinfo*.user!all (stringify:unique-id)))

  (let sname userinfo*.user!all
    (unless userinfo*.user!stations.sname
      (ensure-station2 user sname)
      (= userinfo*.user!initial-groups
         (shuffle:map stringify signup-groups*))

      (= userinfo*.user!signup-showlist (queue))
      (each group userinfo*.user!initial-groups
        (enq random-story-from.group
             userinfo*.user!signup-showlist)))))

(mac modal(show . body)
  `(do
    (tag (div id 'rwmodal style ,show)
      (tag:div class 'rwoverlay-decorator style ,show)
      (tag (div class 'rwoverlay-wrap)
        (tag (div class 'rwoverlay)
          (tag:div class 'rwdialog-decorator)
          (tag (div class 'rwdialog-wrap)
            (tag (div id 'rwdialog class 'rwdialog)
              ,@body)))))))

(def signup-form(user query req)
  (modal "display:block"
    (tag (div style "background:#fff; padding:1em; margin-bottom:100%")
      (prbold "Thank you!")
      (br)
      (tag (span style "font-size:14px; color:#888888")
        (pr "Please save your preferences."))
      (br2)
      (fnform (fn(req) (create-handler req 'register
                                (list (fn(new-username ip)
                                        (swap userinfo*.user
                                              userinfo*.new-username)
                                        (signup new-username ip))
                                      "/")))
              (fn() (pwfields "signup"))
              t)))

  ; example rendering
  (tag (div style "width:960px")
    (with-history-sub req user query
      (doc-panel user query (next-doc user query)))))

(def progress-bar(user)
  (tag div
    (tag (div style "float:left")
      (pr "Progress: "))
    (tag (div class 'rwprogress style "width:8em")
      (tag (div class 'rwprogress_filled
                style (+ "width:"
                         (int:* 8 (/ userinfo*.user!signup-stage
                                     funnel-signup-stage*))
                         "em;"))))
    (clear)))

(def render-doc-with-context2(user sname doc)
  (progress-bar user)
  (if doc
    (do
      (tag (div id (+ "doc_" doc))
        (tag (div style "width:100%; margin-right:1em")
              (when (is 2 userinfo*.user!signup-stage)
                (flash:+ "Ok! We'll now gauge your tastes using " quiz-length*
                         " stories.<br>
                         Vote for the stories or sites that you like."))
          (feedback-form sname doc)
          (tag (div class 'rwpost)
            (render-doc doc)))
        (tag div
          (buttons2 user sname doc)))
      (update-title doc-title.doc))
    (do
      (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
      (write-feedback user "" sname "" "No result found"))))

(def buttons2(user sname doc)
  (tag (div class 'rwbuttons)
    (button2 user sname doc 2 "rwlike" "&#8593;")
    (tag p)
    (button2 user sname doc 1 "rwskip" "&#8595;"))
    (clear))

(def button2(user sname doc n cls label)
  (votebutton cls label
            (inline "rwcontent"
                    (+ "/docupdate2?doc=" urlencode.doc
                       "&station=" urlencode.sname "&outcome=" n))))

(defop docupdate2 req
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome"))
    (nopr
      (ensure-station2 user sname)
      (mark-read2 user sname doc outcome)
      (++ userinfo*.user!signup-stage))
    (next-stage user sname req)))

(proc mark-read2(user sname doc outcome)
  (with (station  userinfo*.user!stations.sname
         feed     doc-feed.doc)
    (erp outcome " " doc)

    (unless userinfo*.user!read.doc
      (push doc station!read-list))
    (= userinfo*.user!read.doc outcome)

    (when (is outcome "2")
      (each g (erp:signup-group-mapping*:car userinfo*.user!initial-groups)
        (or= station!groups.g (backoff doc 2))))
    (deq userinfo*.user!signup-showlist)))

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
