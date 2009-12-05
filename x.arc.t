(include "arctap.arc")  

(include "x.arc")

(test-iso "set works"
  (obj a t b t)
  (Set 'a 'b))

(= docinfo*
    (obj
      "a.com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a.com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "b.com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

(= userinfo*
    (obj
      0 (obj read (table))))

(ok (no:current-user-read "a.com_a"))

(ok (in (doc-from-site "a.com") "a.com_a" "a.com_b")
    "doc-from-site should return a doc from same site")

(= userinfo*
    (obj
      0 (obj read (Set "a.com_a"))))

(ok (current-user-read "a.com_a"))

(test-iso "doc-from-site should pick an unread doc"
  "a.com_b"
  (doc-from-site "a.com"))
