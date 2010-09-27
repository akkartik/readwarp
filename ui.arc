(defop || req
  (let user current-user.req
    (ensure-user user)
    (if signedup?.user
      (flashpage user)
      (scrollpage user))))

(def render-doc(user doc)
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
    (tag:div class 'rwclear)))



(def scrollpage(user (o choosefn choose-feed))
  (tag html
    (header)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwscrollpage)
          (spinner)
          (nav user)
          (tag (div style "width:100%")
            (tag (div id 'rwscrollcontents-wrap)
              (tag (div id 'rwscrollcontent)
                (another-scroll user choosefn)
                (tag script
                  (pr "window.onload = setupScroll;"))))))))))

(defop scrollview req
  (another-scroll current-user.req))

(def another-scroll(user (o choosefn choose-feed))
  (repeat history-size*
    (let doc (pick user choosefn)
      (mark-read user doc)
      (tag (div id (+ "doc_" doc))
        (tag (div class "rwscrollpost-wrapper rwrounded rwshadow")
          (tag (div class "rwscrollpost rwcollapsed")
            (tag (div style "float:right; margin-left:3em")
              (tag (div style "float:right; color:#8888ee; cursor:pointer;"
                        onclick (+ "$('#doc_" doc "').fadeOut('fast');"))
                (pr "x"))
              (tag (div style "float:left; color:#8888ee; cursor:pointer;"
                        onclick (+ "$('#doc_" doc "').fadeTo('fast', 0.8); upvote('" doc "')"))
                (tag (div title "like" class "rwscrollbutton rwscrolllike")))
              (tag (div style "float:left; color:#8888ee; cursor:pointer;"
                        onclick (+ "$('#doc_" doc "').fadeOut('fast'); downvote('" doc "')"))
                (tag (div title "skip" class "rwscrollbutton rwscrollskip"))))
            (tag script
              (pr "++pageSize;"))
            (render-doc user doc))
          (tag:img id (+ "expand_contents_" doc) src "green_arrow_down.png" height "30px" style "float:right"
                   onclick (+ "$(this).hide(); $('#doc_" doc " .rwscrollpost').removeClass('rwcollapsed')")))
        (tag:div class "rwclear rwsep"))))
  (tag script
    (pr "maybeRemoveExpanders();")))

(defop vote req
  (vote current-user.req (arg req "doc") (arg req "outcome")))



(def flashpage(user)
  (tag html
    (header)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwflashpage)
          (nav user)
          (tag (div style "width:100%")
            (tag (div id 'rwflashcontents-wrap)
              (tag (div id 'rwflashcontent)
                (tag script
                  (pr "$(document).ready(renderFlash);"))))))))))

(defop flashview req
  (let user current-user.req
    (aif (arg req "outcome")
      (vote current-user.req (arg req "doc") it))
    (another-flash user
                   (or (only.hash-doc (arg req "hash"))
                       (pick user choose-feed)))))

(def another-flash(user doc)
  (tag (div id (+ "doc_" doc))
    (tag (div id 'rwflashbuttons class "rwbutton-shadow rwrounded-left")
      (like-button user doc)
      (next-button user doc)
      (skip-button user doc))
    (tag (div class "rwflashpost-wrapper rwrounded rwshadow")
      (tag (div class 'rwscrollpost)
        (tag script
          (pr:+ "updateLocation('#" doc-hash.doc "');"))
        (render-doc user doc)))
    (tag:div class "rwclear rwsep")
    (update-title doc-title.doc)))

(def update-title(s)
  (if (empty s)
    (= s "Readwarp")
    (= s (+ s " - Readwarp")))
  (tag script
    (pr (+ "document.title = \"" jsesc.s "\";"))))



(def docUpdate(doc params)
  (+ "docUpdate('" jsesc.doc "', " params ")"))

(proc like-button(user doc)
  (tag (div title "like" class "rwflashbutton rwflashlike" onclick
          (docUpdate doc "'outcome=4'"))))

(proc next-button(user doc)
  (tag (div title "next" class "rwflashbutton rwflashnext" onclick
          (docUpdate doc "'outcome=2'"))))

(proc skip-button(user doc)
  (tag (div title "dislike" class "rwflashbutton rwflashskip" onclick
          (docUpdate doc "'outcome=1'"))))

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



(proc logo-small()
  (tag (a href "http://readwarp.com" class 'rwlogo-button)
    (tag:img src "readwarp-small.png" style "width:150px")))

(proc nav(user)
  (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
    (tag (div style "float:right; margin-top:10px")
      (tag (span style "margin-right:1em")
        (link "feedback" "mailto:feedback@readwarp.com"))
      (if signedup?.user
        (link "logout" "/logout")
        (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                (pr "login"))))
    (logo-small))
  (tag:div class "rwclear rwsep"))



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
    (tag html
      (header)
      (tag body
        (tag (div id 'rwbody)
          (tag (div id 'rwscrollpage)
            (nav user)
            (tag (div style "background:white; padding:2em" class "rwrounded rwshadow")
              (pr "Drag this link to your browser toolbar.")
              (br2)
              (pr "<a href='javascript:var x = new XMLHttpRequest();x.open(\"GET\", \"http://readwarp.com/submit?msg=CRAWL%20" user "%20\"+location.href);x.send(null);alert(\"ReadWarp: submitted, thank you.\");'>Submit to Readwarp</a>")
              (br2)
              (pr "Anytime you click on it thereafter, it will submit the page you're on to Readwarp."))
            (tag:div class "rwclear rwsep")))))))

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
