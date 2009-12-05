(include "arctap.arc")  

(include "x.arc")

(test-iso "set works"
  (obj a t b t)
  (Set 'a 'b))

(= docinfo*
    (obj
      "a.com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a" date (seconds))
      "a.com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b" date (time-ago 1800))
      "b.com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a" date (time-ago 45))))

(= userinfo*
    (obj
      0 (obj read (table))))

(ok (no:current-user-read "a.com_a"))

(test-iso "site-docs should return docs from same site"
  '("a.com_a" "a.com_b")
  (site-docs "a.com"))

(= userinfo*
    (obj
      0 (obj read (Set "a.com_a"))))

(ok (current-user-read "a.com_a"))

(test-iso "site-docs should return unread docs"
  '("a.com_b")
  (site-docs "a.com"))

(let doc (random-unread)
  (ok (no:current-user-read doc))
  (ok (no:current-user-read doc) "random-unread should return an unread doc")
  (current-user-mark-read doc)
  (ok (current-user-read doc))
  (ok (no:iso (random-unread) doc) "random-unread should return different docs"))
