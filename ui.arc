(mac page body
  `(tag html
    (header)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          ,@body
          (tag:div class 'rwclear)
          (tag:div class 'rwsep))))))

(mac with-history(req user station . body)
  `(page
    (nav ,user)
    (tag (div style "width:100%")
      (with-history-sub ,req ,user ,station
        ,@body))))

(mac with-history-sub(req user sname . body)
  `(do
    (tag (div id 'rwright-panel)
      (tag (div id 'rwchannels class "rwrounded rwshadow")
        (current-channel-link ,user ,sname)
        (channels-panel ,user ,sname)
        (bookmarks-link ,user))
      (tag:div class 'rwsep)
      (history-panel ,user ,sname ,req))

    (tag (div id 'rwcontents-wrap)
       (tag (div id 'rwcontent)
         ,@body))))



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
      (doc-panel user sname (next-doc user sname)
        (fn()
          (when new-sname
            (if (len> userinfo*.user!stations.sname!groups 10)
              (flash "Hmm, I don't understand that query. Sorry :(<br/>
                      I'm going to go off and try to pinpoint what you mean, which
                      may take a day.<br/>
                      In the meantime, I'll try to narrow down what you mean,
                      but it may take ~20 stories to do so.<br/>
                     <b>Please try a different query to avoid utterly random stories.</b>")
              (flash "You're now browsing in a new channel.<p>
                     Votes here will not affect recommendations on other
                     channels."))))))))

(defop delstation req
  (withs (user (current-user req)
          sname (arg req "station"))
    (wipe userinfo*.user!stations.sname)))

(def reader(req)
  (withs (user current-user.req
          global-sname (or= userinfo*.user!all (stringify:unique-id)))
    (ensure-station user global-sname)
    (with-history req user global-sname
      (doc-panel user global-sname (next-doc user global-sname)
        (fn()
          (firsttime userinfo*.user!noob
            (set-funnel-property user "signup" "true")
            (signup-funnel-analytics is-prod.req userinfo*.user!signup-stage user)
            (flash
              "Thank you! Keep voting on stories as you read, and
               Readwarp will continually fine-tune its recommendations.
               <br><br>
               Readwarp is under construction. If it seems confused, try
               creating a new channel. And send us feedback!")))))))

(defop docupdate req
  (if (is "bookmarks" (arg req "station"))
    (update-bookmarks req)
    (update-station req)))

(def update-station(req)
  (with (user (current-user req)
         sname (or (arg req "station") "")
         doc (arg req "doc")
         outcome (arg req "outcome")
         prune-feed (is "true" (arg req "prune"))
         group (arg req "group")
         prune-group (is "true" (arg req "prune-group")))
    (ensure-station user sname)
    (mark-read user sname doc outcome prune-feed group prune-group)
    (doc-panel user sname (next-doc user sname))))

(defop doc req
  (with (user (current-user req)
         sname (arg req "station")
         doc (arg req "doc"))
    (if (is sname "bookmarks")
      (bookmarked-doc-panel user
                 (check doc ~blank next-save.user))
      (doc-panel user sname
                 (check doc ~blank (next-doc user sname))))))

(init history-size* 10) ; sync with application.js

(def history-panel-body(user sname req)
  (or= sname "")
  (ensure-station user sname)
  (let items (read-list user sname)
    (paginate req "rwhistory" (+ "/history?station=" urlencode.sname)
              history-size* len.items
        reverse t nextcopy "&laquo;older" prevcopy "newer&raquo;"
      :do
        (tag (div id 'rwhistory-elems)
          (each doc (cut items start-index end-index)
            (render-doc-link user sname doc))))))

(defop history req
  (history-panel-body current-user.req (arg req "station") req))



(def next-doc(user sname)
  (w/stdout (stderr) (pr user " " sname " => "))
  (erp:pick user userinfo*.user!stations.sname))

(def doc-panel(user sname doc (o flashfn))
  (if doc
    (doc-panel-sub user sname doc flashfn)
    (doc-panel-error user sname)))

(def doc-panel-sub(user sname doc flashfn)
  (tag (div id (+ "doc_" doc))
    (tag div
      (buttons user sname doc))
    (tag (div id 'rwpost-wrapper class "rwrounded rwshadow")
      (if flashfn (flashfn))
      (tag (div class 'rwhistory-link style "display:none")
        (render-doc-link user sname doc))
      (tag (div id 'rwpost)
        (feedback-form user sname doc)
        (render-doc user doc)))
    (clear))
  (update-title doc-title.doc))

(def doc-panel-error(user sname)
  (prn "Oops, there was an error. I've told Kartik. Please try reloading the page. And please feel free to use the feedback form &rarr;")
  (write-feedback user "" sname "" "No result found"))

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

(def render-doc-link(user sname doc)
  (tag (div id (+ "history_" doc))
    (unless (is "bookmarks" sname)
      (tag (div id (+ "outcome_" doc)
                class (+ "rwoutcome_icon rwoutcome_" (read? user doc)))
        (pr "&#9632;")))
    (tag (p class 'rwitem)
      (tag (a onclick (+ "showDoc('" jsesc.sname "', '" jsesc.doc "')") href "#")
        (pr (check doc-title.doc ~empty "no title"))))))

(def buttons(user sname doc)
  (tag (div id 'rwbuttons class "rwbutton-shadow rwrounded-left")
    (tag (div title "next" class "rwbutton rwlike" onclick
              (pushHistory sname doc (+ "'outcome=" 2 "'"))))
    (tag (div title "like" class "rwbutton rwsave" onclick
            (pushHistory sname doc (+ "'outcome=" vote-bookmark* "'"))))
    (tag (div title "skip" class "rwbutton rwskip" onclick
            (pushHistory sname doc
                         (maybe-prompt user sname doc "outcome=1"))))
    (email-button user doc)))

(def maybe-prompt(user sname doc default)
  (or
    (unless (is sname "bookmarks")
      (if
        (and (borderline-preferred-feed user sname doc)
             (~empty doc-feedtitle.doc))
           (addjsarg
             default
             (check-with-user
               (+ "I will stop showing articles from\\n"
                  "  " doc-feedtitle.doc "\\n"
                  "in this channel. (press 'cancel' to keep showing them)")
               "prune"))
        (awhen (borderline-unpreferred-group user sname doc)
           (addjsarg
             (+ default "&group=" it)
             (check-with-user
               (+ "I will stop showing any articles about\\n"
                  "  " uncamelcase.it "\\n"
                  "in this channel. (press 'cancel' to keep showing them)")
               "prune-group")))))
    (+ "'" default "'")))

(def email-button(user doc)
  (tag (div onclick "$('rwemail').toggle();
                     $('rwform-flash').innerHTML='';
                     $('rwform-flash').hide()")
    (tag:img src "email.jpg")))



(proc logo-small()
  (tag (div style "text-align:left")
    (tag (a href "/" class 'rwlogo-button)
      (pr "Readwarp"))))

(proc nav(user)
  (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
    (tag (div style "float:right")
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

(def current-channel-link(user sname)
  (when (and sname
             (~is sname userinfo*.user!all))
    (tag (div style "margin-bottom:1em")
      (tag b (pr "current channel"))
      (tag div (pr sname)))))

(def channels-panel(user sname)
  (tag (div class "rwstations rwvlist")
    (when (or (> (len-keys userinfo*.user!stations) 2)
            (and (is 2 (len-keys userinfo*.user!stations))
                 (is sname userinfo*.user!all)))
      (tag b
        (if (is sname userinfo*.user!all)
          (pr "my channels")
          (pr "other channels")))
      (each s (keys userinfo*.user!stations)
        (when (and (~is s userinfo*.user!all)
                 (~is s sname)
                 (~blank s))
          (tag (div class 'rwstation)
            (tag (div style "float:right; margin-right:0.5em")
              (tag (a href (+ "/delstation?station=" urlencode.s)
                      onclick "jsget(this); del(this.parentNode.parentNode); return false;")
                (tag:img src "close_x.gif")))
            (link s (+ "/station?seed=" urlencode.s))))))
    (new-channel-form)))

(def new-channel-form()
  (tag div
    (tag b (pr "new channel"))
    (tag (form action "/station")
         (tag:input name "seed" size "10")
         (tag:input type "submit" value "go" style
                    "margin-top:5px;margin-left:5px")
         (tag (div style "font-size:90%; margin-top:2px")
           (pr "type in a website or author")))))

(def history-panel(user sname req)
  (tag (div id 'rwhistory-wrapper class "rwvlist rwrounded rwshadow")
    (tag b
      (pr "recently viewed"))
    (tag (div id 'rwhistory)
      (history-panel-body user sname req))))



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
      (prn "Sent from http://readwarp.com"))))

(def user-email(user)
  (if (pos #\@ user)
    user
    userinfo*.user!email))

(def feedback-form(user sname doc)
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
      (tag:input type "hidden" name "location" value (+ "/station?seed=" sname))
      (tag:input type "hidden" name "station" value sname)
      (tag:input type "hidden" name "doc" value doc)
      (tag (div style "margin-top:0.5em; text-align:left")
        (do
          (tag:input type "submit" value "send" style "margin-right:1em")
          (tag:input type "button" value "cancel" onclick "$('rwfeedback').toggle()"))))
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
  (w/stdout (stderr) (system "date"))
  (erp "FEEDBACK " current-user.req " " (arg req "msg"))
  (write-feedback (current-user req)
                  (arg req "email")
                  (arg req "station")
                  (arg req "doc")
                  (arg req "msg"))
  (arg req "location"))

(defop submit req
  (w/outstring o ((srvops* 'feedback) o req)))

(defop bookmarklet req
  (let user current-user.req
    (page
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
