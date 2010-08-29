(mac page(req . body)
  `(tag html
    (header ,req)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          ,@body
          (tag:div class 'rwclear)
          (tag:div class 'rwsep))))))

(defop || req
  (let user current-user.req
    (whenlet query (arg req "q")
      (ensure-user user)
      (create-query user query))
    (reader req readwarp-buttons* readwarp-widgets*
      (fn()
        (tag (div style "float:right; margin-top:10px")
          (tag (span style "margin-right:1em")
            (link "feedback" "mailto:feedback@readwarp.com"))
          (if signedup?.user
            (link "logout" "/logout")
            (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                    (pr "login")))))
      (fn()
        (firsttime userinfo*.user!noob
          (flash
            "Keep voting on stories as you read, and Readwarp will
            continually fine-tune its recommendations.
             <br><br>
             If you want a different topic ask for a site about that
             topic in the left."))))))

(def reader(req buttons widgets (o headerfn) (o flashfn))
  (let user current-user.req
    (ensure-user user)
    (page req
      (spinner)
      (nav headerfn)
      (tag (div style "width:100%")
        (tag (div id 'rwcontents-wrap)
          (tag (div id 'rwcontent)
            (tag script
              (pr "window.onload = initPage;"))))))))

(defop docupdate req
  (docupdate-core current-user.req req choose-from-popular
                  readwarp-buttons* readwarp-widgets*))

(def docupdate-core(user req choosefn buttons widgets (o flashfn))
  (ensure-user user)
  (with (doc (arg req "doc")
         outcome (arg req "outcome")
         group (arg req "group"))
    (when (arg req "samesite")
      (pick-from-same-site user lookup-feed.doc))
    (let nextdoc (pick user choosefn)
      (doc-panel user choosefn buttons widgets
        (fn()
          (test*.flashfn)
          ; TODO samesite broken
          (when (and (arg req "samesite")
                     (~is lookup-feed.doc lookup-feed.nextdoc))
            (flash "No more stories from that site")))))))

(defop doc req
  (doc-panel current-user.req choose-from-popular
             readwarp-buttons* readwarp-widgets*))

(def doc-from(req choosefn)
  (let fragment (arg req "id")
    (if (~blank fragment)
      (hash-doc fragment)
      (pick current-user.req choosefn))))

(defop askfor req
  (with (user current-user.req
         query (arg req "q"))
    (erp "askfor: " user " " query)
    (create-query user query)
    (let nextdoc (pick user choose-from-popular)
      (doc-panel user choose-from-popular readwarp-buttons* readwarp-widgets*
        (fn() (flashmsg nextdoc query))))))

(def flashmsg(doc query)
  (let feeds scan-feeds.query
    (if
      (no feeds)
        (flash "Hmm, I don't know that site. Please try again.
               <br><i>(Notifying operator. You can provide details by clicking
                &lsquo;feedback&rsquo; below.)</i>")
      (~pos lookup-feed.doc feeds)
        (flash "No more stories from that site"))))



(def doc-panel(user choosefn buttons widgets (o flashfn))
  (repeat 10
    (let doc (pick user choosefn)
      (mark-read user doc)
      (tag (div id (+ "doc_" doc))
        (tag (div class "rwpost-wrapper rwrounded rwshadow")
          (tag (div class "rwpost rwcollapsed")
            (tag (div style "float:right; color:#8888ee; cursor:pointer;"
                      onclick (+ "$('#doc_" doc "').fadeOut(); downvote('" doc "')"))
              (pr "x"))
            (tag (div style "float:right; color:#8888ee; cursor:pointer;"
                      onclick (+ "$('#doc_" doc "').fadeOut(); upvote('" doc "')"))
              (tag (div title "like" class "rwbutton rwlike")))
            (render-doc user doc widgets))
          (tag:img id (+ "expand_contents_" doc) src "green_arrow_down.png" height "30px" style "float:right"
                   onclick (+ "$(this).hide(); $('#doc_" doc " .rwpost').removeClass('rwcollapsed')")))
        (clear)
        (tag:div class 'rwsep))))
  (tag script
    (pr "maybeRemoveExpanders();")))

(defop vote req
  (vote current-user.req (arg req "doc") (arg req "outcome") "dummygroup"))

(def render-doc(user doc widgets)
  (tag script
    (pr "++pageSize;"))
  (tag (div id (+ "contents_" doc) class 'rwpost-contents)
    (tag (h2 class 'rwtitle)
      (tag (a href doc-url.doc target "_blank" style "margin-right:1em")
        (pr (check doc-title.doc ~empty "no title")))
      (copy-widget doc-url.doc))
    (tag (div class 'rwsubtitle)
      (tag (div class 'rwdate)
        (aif pubdate.doc (pr render-date.it)))
      (whenlet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (check doc-feedtitle.doc ~empty "website")))))
    (tag (div class 'rwpost-body)
      (pr:contents doc))
    (clear)))

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

(= readwarp-buttons* (list ask-button like-button dislike-button))



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

(defop submit req
  (let user current-user.req
    (pipe-to (system "sendmail -t -f feedback@readwarp.com")
      (prn "To: akkartik@gmail.com")
      (prn "Subject: crawl request from " user)
      (prn)
      (prn:arg req "msg"))))

(defop bookmarklet req
  (let user current-user.req
    (page req
      (nav)
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

(def spinner()
  (tag (div id "spinner" style "position:fixed; top:90%; left:90%; z-index:3000; display:none")
    (tag:img src "waiting.gif")))
