(mac page(req . body)
  `(tag html
    (header ,req)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          ,@body
          (tag:div class 'rwclear)
          (tag:div class 'rwsep))))))

(= user-msg* (obj
  ))



(defop || req
  (let user current-user.req
    (whenlet query (arg req "q")
      (ensure-user user)
      (create-query user query))
    (if userinfo*.user
      (reader req choose-feed readwarp-buttons* readwarp-widgets*
        (fn()
          (tag (div style "float:right; margin-top:10px")
            (if signedup?.user
              (link "logout" "/logout")
              (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                      (pr "login")))))
        (fn()
          (firsttime userinfo*.user!noob
            (when voting-stats*.user
              (set voting-stats*.user!signup))
            (flash
              "Keep voting on stories as you read, and Readwarp will
              continually fine-tune its recommendations.
               <br><br>
               If you want a different topic ask for a site about that
               topic in the left."))))
      (start-funnel req))))

(def reader(req choosefn buttons widgets (o headerfn) (o flashfn))
  (let user current-user.req
    (ensure-user user)
    (page req
      (nav headerfn)
      (tag (div style "width:100%")
        (tag (div id 'rwcontents-wrap)
          (tag (div id 'rwcontent)
            (tag script
              (pr "
    $(document).ready(function() {
            $(window).bind('hashchange', function(e){ getDoc(location.hash);});
            getDoc(location.hash);
    });"))))))))

(defop docupdate req
  (let user current-user.req
    (docupdate-core user req choose-feed
                    readwarp-buttons* readwarp-widgets*)))

(def docupdate-core(user req choosefn buttons widgets (o flashfn))
  (ensure-user user)
  (with (doc (arg req "doc")
         outcome (arg req "outcome")
         group (arg req "group"))
    (mark-read user doc outcome group)
    (when (arg req "samesite")
      (pick-from-same-site user doc-feed.doc))
    (let nextdoc (pick user choosefn)
      (doc-panel user nextdoc buttons widgets
        (fn()
          (test*.flashfn)
          (tag (div style "float:right; cursor:pointer; background:lightgrey; padding:3px")
            (tag (a onclick (+ "showDoc('" doc "')"))
              (pr "previous story")))
          (when (and (arg req "samesite")
                     (~is doc-feed.doc doc-feed.nextdoc))
            (flash "No more stories from that site")))))))

(defop askfor req
  (with (user current-user.req
         query (arg req "q"))
    (erp "askfor: " user " " query)
    (create-query user query)
    (let nextdoc (pick user choose-feed)
      (doc-panel user nextdoc readwarp-buttons* readwarp-widgets*
        (fn() (flashmsg nextdoc query))))))

(def flashmsg(doc query)
  (let feeds scan-feeds.query
    (if
      (no feeds)
        (flash "Hmm, I don't know that site. Please try again.
               <br><i>(Notifying operator. You can provide details by clicking
                &lsquo;feedback&rsquo; below.)</i>")
      (~pos doc-feed.doc feeds)
        (flash "No more stories from that site"))))

(defop doc req
  (withs (user (current-user req)
          doc  (check (arg req "doc")
                      ~blank
                      (pick user choose-feed)))
    (doc-panel user doc readwarp-buttons* readwarp-widgets*)))



(def doc-panel(user doc buttons widgets (o flashfn))
  (if doc
    (doc-panel-sub user doc buttons widgets flashfn)
    (doc-panel-error user)))

(def doc-panel-sub(user doc buttons widgets flashfn)
  (tag (div id (+ "doc_" doc))
    (tag (div id 'rwbuttons class "rwbutton-shadow rwrounded-left")
      (each b buttons
        (b user doc)))
    (tag (div id 'rwpost-wrapper class "rwrounded rwshadow")
      (when (and (~signedup? user)
                 userinfo*.user!noob)
        (signup-form user))
      (test*.flashfn)
      (only.flash user-msg*.user)
      (tag (div id 'rwpost)
        (feedback-form user doc)
        (render-doc user doc widgets)))
    (clear))
  (update-title doc-title.doc))

(def doc-panel-error(user)
  (flash "Oops, there was an error. Telling the operator. Please try
          reloading.")
  (write-feedback user "" "" "No result found"))

(def update-title(s)
  (if (empty s)
    (= s "Readwarp")
    (= s (+ s " - Readwarp")))
  (tag script
    (pr (+ "document.title = \"" jsesc.s "\";"))))

(def render-doc(user doc widgets)
  (tag script
    (pr:+ "location.href='#" doc-hash.doc "'"))
  (tag (div id (+ "contents_" doc))
    (tag (h2 class 'rwtitle)
      (tag (a href doc-url.doc target "_blank" style "margin-right:1em")
        (pr (check doc-title.doc ~empty "no title")))
      (each w widgets
        (w doc))
      (email-widget)
      (copy-widget doc-url.doc))
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

(mac ask-button-elem body
  `(tag div
    (tag (span style "color:#ccc")
      (pr "&middot; "))
    ,@body))
(def ask-button(user doc)
  (tag (div id 'rwmagicbox-panel)
    (tag (div style "margin-top:5px;
                    font-size:90%; font-weight:bold; color:#999")
      (pr "next story from:"))
    (ask-button-elem
      (onclick (docUpdate doc "'outcome=4&samesite=1'")
        (pr "this site")))
    (tag (form action "/404" onsubmit "submitMagicBox('rwmagicbox', 'a new site'); return false;")
         (tag (div style "height:24px; color:#aaf; width:10px; margin-right:2px; float:right; cursor:pointer"
                   onclick "submitMagicBox('rwmagicbox', 'a new site'); return false;")
            (pr "&crarr;"))
         (tag (span style "color: #ccc")
           (pr "&middot;"))
         (tag:input name "q" id "rwmagicbox"
                    style "font-size:14px; width:98px; height:24px; color:#999"
                    value "a new site"
                    onfocus "clearDefault(this, 'a new site');"
                    onblur "fillDefault(this, 'a new site');"))
    (each query (firstn 5 userinfo*.user!queries)
      (ask-button-elem
        (onclick (askfor query)
          (pr query))))))

(proc like-button(user doc)
  (tag (div title "like" class "rwbutton rwlike" onclick
          (docUpdate doc "'outcome=4'"))))

(proc next-button(user doc)
  (tag (div title "next" class "rwbutton rwnext" onclick
          (docUpdate doc "'outcome=2'"))))

(proc dislike-button(user doc)
  (tag (div title "dislike" class "rwbutton rwskip" onclick
          (docUpdate doc "'outcome=1'"))))

(= readwarp-buttons* (list ask-button like-button next-button dislike-button))



(def email-widget()
  (tag (span class 'rwsharebutton
            onclick "$('#rwemail').toggle();
                     $i('rwform-flash').innerHTML='';
                     $('#rwform-flash').hide()")
    (tag:img src "email.jpg" height "14px")))

; http://www.facebook.com/facebook-widgets/share.php
(def facebook-widget(doc)
  (sharebutton
    (tag (a href (+ "http://www.facebook.com/sharer.php"
                    "?u=" doc-url.doc
                    "&t=" doc-title.doc)
            target  "_blank")
      (tag:img src "facebook.jpg" height "16px"))))

(def twitter-widget(doc)
  (sharebutton
    (tag (a href (+ "http://twitter.com/home?status=" wrp.doc)
            target  "_blank")
      (tag:img src "twitter.png" height "16px"))))

; http://www.reddit.com/buttons
(def reddit-widget(doc)
  (sharebutton
    (tag (a href (+ "http://reddit.com/submit"
                    "?url=" doc-url.doc
                    "&title=" doc-title.doc)
            target  "_blank")
      (tag:img src "reddit.gif" height "16px"))))

(def hackernews-widget(doc)
  (sharebutton
    (tag (a href (+ "http://news.ycombinator.com/submitlink"
                    "?u=" doc-url.doc
                    "&t=" doc-title.doc)
            target  "_blank")
      (tag:img src "hackernews.gif" height "16px"))))

; http://www.google.com/support/reader/bin/answer.py?hl=en&answer=147149
(def google-widget(doc)
  (sharebutton
    (tag (a href (+ "http://www.google.com/reader/link"
                    "?url=" doc-url.doc
                    "&title=" doc-title.doc)
            target  "_blank")
      (tag:img src "google.png" height "16px"))))

(= readwarp-widgets* (list facebook-widget twitter-widget reddit-widget
                           google-widget))



(proc logo-small()
  (tag center
    (tag (a href "http://readwarp.com" class 'rwlogo-button)
      (tag:img src "readwarp-small.png" style "width:150px"))))

(proc nav((o f))
  (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
    (test*.f)
    (logo-small)
    (clear))
  (tag:div class 'rwsep))

(def docUpdate(doc params)
  (+ "docUpdate('" jsesc.doc "', " params ")"))
(def askfor(query)
  (+ "askFor('" jsesc.query "')"))



(defopr logout req
  (logout-user current-user.req)
  "/")

(def email-form(user doc)
  (tag:div class "rwflash" id "rwform-flash" style "font-size:75%; display:none")
  (tag (form id "rwemail" style "display:none" method "post"
             onsubmit "$('#rwemail').toggle();
                       jspost('/email', params($i('rwemail')));
                       $i('rwform-flash').innerHTML = ' sent';
                       $('#rwform-flash').show();
                       return false")
    (tag h3 (pr "Email this story"))(br)
    (tab
      (tr
        (tag (td style "vertical-align:middle") (prbold "From:&nbsp;"))
        (td:tag:input style "margin-bottom:5px" name "from" size "50"
                      value user-email.user))
      (tr
        (tag (td style "vertical-align:middle") (prbold "To:&nbsp;"))
        (td:tag:input id "email-to" style "margin-bottom:5px" name "to" size "50"))
      (tag script
        (pr "$(function() { $('#email-to').autocomplete({source: [")
        (each e userinfo*.user!contacts
          (pr "\"" e "\", "))
        (pr "]});});"))
      (tr
        (tag (td style "vertical-align:middle") (prbold "Subject:&nbsp;"))
        (td:tag:input style "margin-bottom:5px" name "subject" size "50"
                      value doc-title.doc)))
    (prbold "Note: ") (pr "(optional)")(br)
    (tag (textarea name "msg" cols "60" rows "6" style "text-align:left")
      (prn)
      (prn)
      (prn)
      (prn wrp.doc)
      (prn))
    (tag (div style "margin-top:5px")
      (tag:input name "ccme" id "ccme" type "checkbox"
                 style "width:1em; height:1em")
      (tag (label for "ccme") (pr " Send me a copy")))
    (tag (div style "margin-top:0.5em; text-align:left")
      (do
        (tag:input type "submit" value "send" style "margin-right:1em")
        (onclick "$('#rwemail').toggle()"
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
      (onclick "$('#rwfeedback').toggle(); return false"
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
          (tag:input type "button" value "cancel" onclick "$('#rwfeedback').toggle()"))))
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
  (or= userinfo*.user!all (string:unique-id))
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
      (erp "new user: " user " " req!ip))))
