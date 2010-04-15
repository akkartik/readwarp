(defop save req
  (toggle-save current-user.req (arg req "doc")))

(def toggle-save(user doc)
  (if (pos doc userinfo*.user!saved)
    (nrem doc userinfo*.user!saved)
    (add-to userinfo*.user!saved doc)))

(def bookmarks-link()
  (tag (div class 'rwvlist)
    (tag (a href "/saved")
      (tag b (pr "my bookmarks"))
      (tag:img src "/save.gif" height "14px" style "margin-left:0.5em"))))

(defop saved req
  (let user get-user.req
    (page user
      (nav user)
      (tag (div style "width:100%")
        (tag (div id 'rwright-panel)
          (bookmarks-link)
          (channels-panel user nil)
          (bookmarks-panel user req))

        (tag (div id 'rwcontents-wrap)
          (tag (div id 'rwcontent)
            (bookmarked-doc-panel user next-save.user)))))))

(def next-save(user)
  (carif userinfo*.user!saved))

(init no-bookmarks-msg*
      "You have no bookmarks. Click on the star button to add some.")
(def bookmarked-doc-panel(user doc)
  (if no.doc
    (flash no-bookmarks-msg*)
    (bookmarked-doc-panel-sub user doc)))

(def update-bookmarks(req)
  (with (user current-user.req
         doc (arg req "doc"))
    (when (is "4" (arg req "outcome"))
      (toggle-save user doc))
    (if (no userinfo*.user!saved)
      (flash no-bookmarks-msg*)
      (do
        (when (is doc (car userinfo*.user!saved))
          (nslowrot userinfo*.user!saved))
        (bookmarked-doc-panel-sub user next-save.user)))))

(def bookmarks-panel(user req)
  (tag (div class 'rwvlist)
    (tag b
      (pr "other bookmarks"))
    (tag (div id 'rwhistory)
      (bookmarks-panel-body user req))))

(def bookmarks-panel-body(user req)
  (let items (cdr userinfo*.user!saved)
    (paginate req "rwhistory" "/bhist"
              history-size* len.items
      :do
        (tag (div id 'rwhistory-elems)
          (each doc (cut items start-index end-index)
            (render-doc-link user "bookmarks" doc))))))

(defop bhist req
  (bookmarks-panel-body current-user.req req))

(def bookmarked-doc-panel-sub(user doc)
  (tag (div id (+ "doc_" doc))
    (tag (div id 'rwpost-wrapper)
      (feedback-form "bookmarks" doc)
      (tag (div class 'rwhistory style "display:none")
        (render-doc-link user "bookmarks" doc))
      (tag (div class 'rwpost)
        (render-doc user doc)))
    (tag div
      (bookmark-buttons user doc)))
  (update-title doc-title.doc))

(def bookmark-buttons(user doc)
  (tag (div class 'rwbuttons)
    (votebutton "rwlike" "next"
                (+ "pullFromHistory('" urlencode.doc "');"))

    (tag p)
    (tag (div class 'rwbutton style "width:32px; height:32px; margin-left:30px")
      (toggle-icon (+ "save_" doc)
        (tag div
          (tag:img src IMG width "32px"))
        (+ "/save?doc=" doc)
        "/saved.gif" "/save.gif"
        (pos doc userinfo*.user!saved)))

    (tag (div class 'rwbutton onclick
            (+ "pullFromHistory('" urlencode.doc "');"))
      (tag:img src "signup-down.png" height "90px"))

    (tag p)
    (email-button user doc)
    (clear)))
