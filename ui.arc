(mac page(req . body)
  `(tag html
    (header ,req)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          ,@body
          (tag:div class 'rwclear)
          (tag:div class 'rwsep))))))

(mac with-history(req user . body)
  `(page ,req
    (nav ,user)
    (tag (div style "width:100%")
      (with-history-sub ,req ,user
        ,@body))))

(mac with-history-sub(req user . body)
  `(do
    (tag (div id 'rwright-panel)
      (history-panel ,user ,req))

    (tag (div id 'rwcontents-wrap)
       (tag (div id 'rwcontent)
         ,@body))))

(= user-msg* (obj
  ))



(defop || req
  (if (signedup? current-user.req)
    (reader req)
    (start-funnel req)))

(def reader(req)
  (let user current-user.req
    (ensure-user user)
    (with-history req user
      (doc-panel user next-doc.user
        (fn()
          (firsttime userinfo*.user!noob
            (tag script
              (pr "mpmetrics.register({\"signup\": \"true\"});"))
            (when voting-stats*.user
              (set voting-stats*.user!signup))
            (signup-funnel-analytics is-prod.req userinfo*.user!signup-stage user)
            (flash
              "Thank you! Keep voting on stories as you read, and
               Readwarp will continually fine-tune its recommendations.
               <br><br>
               Readwarp is under construction. If it seems confused, try
               creating a new channel. And send us feedback!")))))))

(defop docupdate req
  (let user current-user.req
    (docupdate-core user req)))

(def docupdate-core(user req)
  (ensure-user user)
  (with (doc (arg req "doc")
         outcome (arg req "outcome")
         group (arg req "group"))
    (mark-read user doc outcome group)
    (when (arg req "samesite")
      (set-current-from user doc-feed.doc))
    (if signedup?.user
      (let nextdoc next-doc.user
        (doc-panel user nextdoc
          (fn()
            (when (and (arg req "samesite")
                       (~is doc-feed.doc doc-feed.nextdoc))
              (flash "No more stories from that site")))))
      (signup-doc-panel user req))))

(defop askfor req
  (let user current-user.req
    (create-query user (arg req "q"))
    (if signedup?.user
      (doc-panel user (next-doc user))
      (signup-doc-panel user req))))

(defop doc req
  (with (user (current-user req)
         doc (arg req "doc"))
    (doc-panel user
               (check doc ~blank next-doc.user))))

(init history-size* 10) ; sync with application.js

(def history-panel-body(user req)
  (ensure-user user)
  (let items (read-list user)
    (paginate req "rwhistory" "/history"
              history-size* len.items
        reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
      :do
        (tag (div id 'rwhistory-elems)
          (each doc (cut items start-index end-index)
            (render-doc-link user doc))))))

(defop history req
  (history-panel-body current-user.req req))



(def next-doc(user)
  (ret doc pick.user
    (erp user " => " doc)))

(def doc-panel(user doc (o flashfn))
  (if doc
    (doc-panel-sub user doc flashfn)
    (doc-panel-error user)))

(def doc-panel-sub(user doc flashfn)
  (tag (div id (+ "doc_" doc))
    (tag div
      (buttons user doc))
    (tag (div id 'rwpost-wrapper class "rwrounded rwshadow")
      (when flashfn (flashfn))
      (only.flash user-msg*.user)
      (unless userinfo*.user!read.doc
        (tag (div class 'rwhistory-link style "display:none")
          (render-doc-link user doc)))
      (tag (div id 'rwpost)
        (feedback-form user doc)
        (render-doc user doc)))
    (clear))
  (update-title doc-title.doc))

(def doc-panel-error(user)
  (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
  (write-feedback user "" "" "No result found"))

(def update-title(s)
  (if (empty s)
    (= s "Readwarp")
    (= s (+ s " - Readwarp")))
  (tag script
    (pr (+ "document.title = \"" jsesc.s "\";"))))

(def render-doc(user doc)
  (tag (div id (+ "contents_" doc))
    (tag (h2 class 'rwtitle)
      (tag (a href doc-url.doc target "_blank")
        (pr (check doc-title.doc ~empty "no title")))
      (email-button user doc)
      (copywidget doc-url.doc))
    (tag (div class 'rwsubtitle)
      (tag (div class 'rwdate)
        (aif pubdate.doc (pr render-date.it)))
      (whenlet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (check doc-feedtitle.doc ~empty "website")))))
    (email-form user doc)
    (tag (div id 'rwpost-body)
      (pr:contents doc))
    (clear)))

(def render-doc-link(user doc)
  (tag div
    (tag (div id (+ "outcome_" doc)
              class (+ "rwoutcome_icon rwoutcome_" (read? user doc)))
      (pr "&#9632;"))
    (tag (p class 'rwitem)
      (tag (a onclick (+ "showDoc('" jsesc.doc "')") href "#")
        (pr (check doc-title.doc ~empty "no title"))))))

(def buttons(user doc)
  (tag (div id 'rwbuttons class "rwbutton-shadow rwrounded-left")
    (tag (div title "like" class "rwbutton rwlike" onclick
            (pushHistory doc "'outcome=4'")))
    (tag (div title "next" class "rwbutton rwnext" onclick
            (pushHistory doc "'outcome=2'")))
    (tag (div title "dislike" class "rwbutton rwskip" onclick
            (pushHistory doc "'outcome=1'")))
    (magic-box user doc)))

(def email-button(user doc)
  (tag (span style "margin-left:5px"
            onclick "$('rwemail').toggle();
                     $('rwform-flash').innerHTML='';
                     $('rwform-flash').hide()")
    (tag:img src "email.jpg" height "14px")))



(proc logo-small()
  (tag center
    (tag (a href "/" class 'rwlogo-button)
      (tag:img src "readwarp-small.png" style "width:150px"))))

(proc nav(user)
  (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
    (tag (div style "float:right; margin-top:10px")
      (if signedup?.user
        (do
          (tag (span style "margin-right:5em")
            (link "home" "/"))
          (link "logout" "/logout"))
        (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                (pr "login"))))
    (logo-small)
    (clear))
  (tag:div class 'rwsep))

(def magic-box(user doc)
  (tag (div style "border-top:1px #ccc solid")
    (tag (div style "text-align:left; margin-top:5px; margin-left:2px;
                    font-size:90%; color:#999")
      (pr "next story from"))
    (tag (div style "text-align:left; margin-left:5px")
      (tag (a href "#" onclick
              (pushHistory doc "'outcome=4&samesite=1'"))
        (pr "this site")))
    (tag (form id "magicbox" action "/askfor")
         (tag (div style "background:; height:15px; width:1em; float:right; cursor:pointer"
                   onclick "return submitForm(this, 'magicbox', 'a new site');")
            (pr "&rarr;"))
         (tag:input name "q" id "magicbox"
                    style "width:100px; height:17px; color:#999"
                    value "a new site"
                    onfocus "clearDefault(this, 'a new site');"
                    onblur "fillDefault(this, 'a new site');"))
    (each query (firstn 5 userinfo*.user!queries)
      (tag (div style "text-align:left; margin-left:5px")
        (tag (a href "#" onclick
                (askfor query))
          (pr query))))))

(def askfor(query) query)

(def history-panel(user req)
  (tag (div id 'rwhistory-wrapper class "rwvlist rwrounded rwshadow")
    (tag b
      (pr "recently viewed"))
    (tag (div id 'rwhistory)
      (history-panel-body user req))))



(defopr logout req
  (logout-user current-user.req)
  "/")

(def email-form(user doc)
  (tag:div class "rwflash" id "rwform-flash" style "font-size:75%; display:none")
  (tag (form id "rwemail" style "display:none" method "post"
             onsubmit "$('rwemail').toggle();
                       jspost('/email', params($('rwemail')));
                       $('rwform-flash').innerHTML = ' sent';
                       $('rwform-flash').show();
                       return false")
    (tag h3 (pr "Email this story"))(br)
    (tab
      (tr
        (tag (td style "vertical-align:middle") (prbold "From:&nbsp;"))
        (td:tag:input style "margin-bottom:5px" name "from" size "50"
                      value user-email.user))
      (tr
        (tag (td style "vertical-align:middle") (prbold "To:&nbsp;"))
        (td:tag:input style "margin-bottom:5px" name "to" size "50"))
      (tr
        (tag (td style "vertical-align:middle") (prbold "Subject:&nbsp;"))
        (td:tag:input style "margin-bottom:5px" name "subject" size "50"
                      value doc-title.doc)))
    (prbold "Note: ") (pr "(optional)")(br)
    (tag (textarea name "msg" cols "60" rows "6" style "text-align:left")
      (prn)
      (prn)
      (prn)
      (prn doc-url.doc)
      (prn))
    (tag (div style "margin-top:5px")
      (tag:input name "ccme" id "ccme" type "checkbox"
                 style "width:1em; height:1em")
      (tag (label for "ccme") (pr " Send me a copy")))
    (tag (div style "margin-top:0.5em; text-align:left")
      (do
        (tag:input type "submit" value "send" style "margin-right:1em")
        (tag (a href "#" onclick "$('rwemail').toggle()")
          (pr "cancel"))))))

(defop email req
  (let user current-user.req
    (= userinfo*.user!email (arg req "from"))
    (pipe-to (system "sendmail -t -f feedback@readwarp.com")
      (prn "Reply-To: " (arg req "from"))
      (prn "From: Readwarp <feedback@readwarp.com>") ;authsmtp won't let this be from
      (prn "To: " (arg req "to"))
      (when (is "true" (arg req "ccme"))
        (prn "Cc: " (arg req "from")))
      (prn "Bcc: akkartik@gmail.com")
      (prn "Subject: " (arg req "subject"))
      (prn)
      (prn "(" (arg req "from") " shared a link with you.)")
      (prn)
      (prn (arg req "msg"))
      (prn "--")
      (prn "Sent from http://readwarp.com, your source for personalized reading suggestions."))))

(def user-email(user)
  (if (pos #\@ user)
    user
    userinfo*.user!email))

(def feedback-form(user doc)
  (tag (div id 'rwfeedback-wrapper)
    (tag (div class 'rwfeedback_link)
      (tag (a onclick "$('rwfeedback').toggle(); return false" href "#")
        (pr "feedback")))
    (tag (form id 'rwfeedback action "/feedback" method "post" style
               "display:none")
      (tag:textarea name "msg" cols "25" rows "6" style "text-align:left")(br)
      (tag (div style "font-size: 75%; margin-top:0.5em; text-align:left")
        (pr "Your email?"))
      (tag:input name "email" value user-email.user) (tag (i style "font-size:75%") (pr "(optional)")) (br)
      (tag:input type "hidden" name "doc" value doc)
      (tag (div style "margin-top:0.5em; text-align:left")
        (do
          (tag:input type "submit" value "send" style "margin-right:1em")
          (tag:input type "button" value "cancel" onclick "$('rwfeedback').toggle()"))))
    (clear)))

(def write-feedback(user email doc msg)
  (w/prfile (+ "feedback/" (seconds))
    (prn "User: " user)
    (prn "Email: " email)
    (prn "Doc: " doc)
    (prn "Feedback:")
    (prn msg)
    (prn)))

(defopr feedback req
  (w/stdout (stderr) (system "date"))
  (erp "FEEDBACK " current-user.req " " (arg req "msg"))
  (when (is "pk45059" current-user.req)
    (pipe-to (system "sendmail -f feedback@readwarp.com akkartik@gmail.com")
      (prn "pk45059 sent feedback!")))
  (write-feedback (current-user req)
                  (arg req "email")
                  (arg req "doc")
                  (arg req "msg"))
  "/")

(defop submit req
  (w/outstring o ((srvops* 'feedback) o req)))

(defop bookmarklet req
  (let user current-user.req
    (page req
      (nav current-user.req)
      (br2)
      (pr "Drag this link to your browser toolbar.")
      (br2)
      (pr "<a href='javascript:var x = new XMLHttpRequest();x.open(\"GET\", \"http://readwarp.com/submit?msg=CRAWL%20" user "%20\"+location.href);x.send(null);alert(\"ReadWarp: submitted, thank you.\");'>Submit to Readwarp</a>")
      (br2)
      (pr "Anytime you click on it thereafter, it will submit the page you're on to Readwarp."))))

(def signup(user ip)
  (ensure-user user)
  (or= userinfo*.user!all (stringify:unique-id))
  (ensure-station user userinfo*.user!all)
  (unless userinfo*.user!signedup
    (set userinfo*.user!signedup)
    (= userinfo*.user!created (seconds))))

(defop resetpw req
  (let user current-user.req
    (urform user req "/" (set-pw user (arg req "p"))
      (single-input "New password: " 'p 20 "update" t))))

(def signedup?(user)
  (and userinfo*.user userinfo*.user!signedup))

(def current-user(req)
  (ret user get-user.req
    (unless userinfo*.user
      (erp "new user: " user " " req!ip)
      ensure-user.user)))

(persisted loggedin-users* (table))
(defop rusers req
  (when (is req!ip "174.129.11.4")
    (let (returning new) (partition keys.loggedin-users* old-user)
      (prn "Newly signedup: " len.new)
      (prn)
      (prn "Returning: " returning))
    (= loggedin-users* (table))))
(after-exec current-user(req)
  (when userinfo*.result!signedup
    (set loggedin-users*.result)))

(def old-user(user)
  (or (no userinfo*.user!created)
      (< userinfo*.user!created
         (time-ago:* 60 60 24))))

(persisted voting-stats* (table))
(after-exec mark-read(user d outcome g)
  (or= voting-stats*.user (table))
  (++ (voting-stats*.user outcome 0))
  (or= voting-stats*!total (table))
  (++ (voting-stats*!total outcome 0)))
(defop votingstats req
  (when (is req!ip "174.129.11.4")
    (awhen voting-stats*!total
      (prn "TOTAL +" (it "4")
                " =" (it "2")
                " -" (it "1")))
    (each (user info) voting-stats*
      (unless (is 'total user)
        (prn user " +" (or (info "4") 0)
                  " =" (or (info "2") 0)
                  " -" (or (info "1") 0)
                  (if info!signup " SIGNEDUP" ""))))
    (= voting-stats* (table))))

(defop test req
  (unless is-prod.req
    (errsafe:wipe ustation.nil!current)
    (docupdate-core nil req)))
