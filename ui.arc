(defop || req
  (let user current-user.req
    (ensure-user user)
    (scrollpage "" user)))

(def render-doc(user doc)
  (tag (div id (+ "contents_" doc) class 'rwpost-contents)
    (tag (h2 class 'rwtitle)
      (tag (a href doc-url.doc target "_blank")
        (pr (check doc-title.doc ~empty "no title"))))
    (tag (div class 'rwsubtitle)
      (tag (div class 'rwdate)
        (aif pubdate.doc (pr render-date.it)))
      (whenlet siteurl doc-site.doc
        (tag (a href siteurl target "_blank")
          (pr (check doc-feedtitle.doc ~empty "website")))))
    (tag (div class 'rwpost-body)
      (pr:contents doc))
    (tag:div class 'rwclear)))



(def scrollpage(title user ? choosefn choose-feed)
  (ensure-user user)
  (tag html
    (header)
    (tag body
      (tag (div id 'rwbody)
        (tag (div id 'rwpage)
          (nav user title)
          (tag (div style "width:100%")
            (tag (div id 'rwcontents-wrap)
              (tag (div id 'rwcontent)
                (tag script
                  (pr "$(document).bind('keydown', 'x', clickCurrentHide);")
                  (pr "$(document).bind('keydown', 'o', clickCurrentExpander);")
                  (pr "$(document).bind('keydown', 'f', clickCurrentExpander);")
                  (pr "$(document).bind('keydown', 'h', moveLeft);")
                  (pr "$(document).bind('keydown', 'j', moveDown);")
                  (pr "$(document).bind('keydown', 'k', moveUp);")
                  (pr "$(document).bind('keydown', 'l', moveRight);")
                  (pr "window.onload = initPage;")))
              (tag:div id 'morebutton class "rwshadow rwrounded" onclick "nextScrollDoc()")
              (tag:div style "height:1em"))))))))

(defop scrollview req
  (another-scroll current-user.req (only.int (arg req "remaining")) (lookup-chooser (arg req "for"))))

(def another-scroll(user remaining ? choosefn choose-feed)
  (let doc (pick user choosefn)
    (mark-read user doc)
    (tag (div id (+ "doc_" doc) class "rwpost-wrapper rwrounded rwshadow"
              onclick "makeCurrent(this)")
      (tag (div class "rwpost rwcollapsed")
        (tag (div class 'rwbuttons)
          (tag (div class 'rwhidebutton
                    onclick (+ "scrollHide('" doc "')"))
            (pr "x")))
        (render-doc user doc))
      (tag:img id (+ "expand_contents_" doc) class "rwexpander" src "green_arrow_down.png" height "30px" style "float:right"
               onclick (+ "$(this).hide(); $('#doc_" doc " .rwpost').removeClass('rwcollapsed')")))
    (tag:div class "rwclear rwsep"))
  (tag script
    (pr "maybeRemoveExpanders();")
    (pr "++pageSize;")
    (pr "deleteScripts($i('rwcontent'));")
    --.remaining
    (if (and remaining (> remaining 0))
      (pr (+ "nextScrollDoc(" remaining ");")))))



(proc logo-small()
  (tag (a href "http://readwarp.com" class 'rwlogo-button)
    (tag:img src "readwarp-small.png" style "width:150px")))

(mac option(title value text)
  `(tag (option value ,value
                selected (is ,title ,value))
    (pr ,text)))

(proc nav(user ? title nil)
  (tag (div id 'rwnav class "rwrounded-bottom rwshadow")
    (tag (div id 'rwnav-menu)
      (tag (span style "color:#444; margin-right:1em")
        (prn "Discover sites from:")
        (whenlet title (string title)
          (tag (select style "font-size:90%; color:#444"
                       onchange "location.href='/'+this[this.selectedIndex].value")
            (option title "" "the whole web")
            (option title "news" "news")
            (option title "politics" "politics")
            (option title "health" "health")
            (option title "fashion" "fashion")
            (option title "economics" "economics")
            (option title "technology" "technology")
            (option title "art" "art")
            (option title "odd" "odd news")
            (option title "comics" "comics")
            (option title "programming" "programming")
            (option title "startups" "startups"))))
      (tag (span style "margin-right:1em")
        (link "feedback" "mailto:feedback@readwarp.com"))
      (if signedup?.user
        (link "logout" "/logout")
        (w/link (login-page 'both "Please login to Readwarp" (list signup "/"))
                (pr "login"))))

  (tab (tr (td
    (logo-small)
    (tag (span style "font-style:italic; color:#888")
      (pr "The eclectic broadsheet ")
      (tag (span style "color:#ccc")
        (pr (+ "- " (intersperse " " (rev:timedate))))))))))
  (tag:div class "rwclear rwsep"))



(defopr logout req
  (logout-user current-user.req)
  "/")

(defop submit req
  (let user current-user.req
    (mail-me (+ "crawl request from " user "/" (arg req "user"))
             (arg req "msg"))))

(def mail-me(subject message)
  (pipe-to (system "sendmail -t -f feedback@readwarp.com")
    (prn "To: akkartik@gmail.com")
    (prn "Subject: " subject)
    (prn)
    (prn message)))

(defop bookmarklet req
  (let user current-user.req
    (tag html
      (header)
      (tag body
        (tag (div id 'rwbody)
          (tag (div id 'rwpage)
            (nav user)
            (tag (div style "background:white; padding:2em" class "rwrounded rwshadow")
              (pr "Drag this link to your browser toolbar.")
              (br2)
              (pr:+ "<a href='"
"javascript:("
  "function() {"
    "var getRssLink = function(){"
      "var linkTags=document.getElementsByTagName(\"head\")[0].getElementsByTagName(\"link\");"
      "for (var i = 0; i < linkTags.length; ++i) {"
        "if(linkTags[i][\"type\"] == \"application/rss+xml\") return linkTags[i][\"href\"];"
        "if(linkTags[i][\"type\"] == \"application/atom+xml\") return linkTags[i][\"href\"];"
      "}"
    "};"
    "var backupRequest = function(){"
      "var x = new XMLHttpRequest();"
      "x.open(\"GET\", \"http://readwarp.com/submit?msg=CRAWL%20" user "%20\"+location.href);"
      "x.send(null);"
      "alert(\"ReadWarp: I don&#39;t see the feed, but Kartik will manually add it tonight.\");"
    "};"
    "try{"
      "var feed = getRssLink();"
      ; feed must be the last arg for when lookup-chooser gets location.href
      "if (feed != undefined) window.open(\"http://readwarp.com/crawlsubmit?user=" user "&feed=\"+feed);"
      "else backupRequest();"
    "}"
    "catch(err) {"
      "backupRequest();"
    "}"
  "}"
")();"
              "'>Submit to Readwarp</a>")
              (br2)
              (pr "Anytime you click on it thereafter, it will submit the page you're on to Readwarp."))
            (tag:div class "rwclear rwsep")))))))

(let priority-crawl-fifo* (outfile "fifos/tocrawl")
  (defop crawlsubmit req
    (let feed (arg req "feed")
      (erp "CRAWLSUBMIT  " current-user.req " " (arg req "user") " " feed)
      (pushline feed priority-crawl-fifo*)
      (mail-me (+ "crawlsubmit from " current-user.req "/" (arg req "user"))
               feed)
      (unless docs.feed
        (erp "waiting for crawl")
        (wait docs.feed)
        (erp "arrived"))
      (scrollpage current-user.req feed-chooser.feed))))

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

(= lookup-chooser* (table))
(mac defpage(url group)
`(do
   (= (lookup-chooser* (+ "http://readwarp.com/" ',url)) (group-chooser ,group))
   (defop ,url req
      (scrollpage ',url current-user.req (group-chooser ,group)))))

(defpage news "News")
(defpage politics "Politics")
(defpage health "Health")
(defpage fashion "Fashion")
(defpage economics "Economics")
(defpage technology "Technology")
(defpage art "Art")
(defpage odd "Odd")
(defpage comics "Comics")
(defpage programming "Programming")
(defpage startups "Venture")
(defpage cricket "Cricket")

(def lookup-chooser(arg)
  (or lookup-chooser*.arg
      (only.feed-chooser feed-from.arg)
      choose-feed))

(def feed-from(url)
  (whenlet idx (findsubseq "http" url 1)
    (cut url idx)))

; Hack - we want to be able to reload ui.arc on the production server without
; breaking daily email.
(if (bound 'loggedin-users*)
  (load "ops.arc"))
