(include "arctap.arc")  

(= docinfo*
    (obj
      "a.com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a.com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "b.com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

(include "x.arc")

(ok (in (doc-from-site "a.com") "a.com_a" "a.com_b")
    "doc-from-site should return a doc from same site")

(= docinfo*
    (obj
      "a.com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a.com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "b.com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

(= userinfo*
    (obj
      0 'read ("a.com_a")))

(test-iso "doc-from-site should pick an unread doc"
  "a.com_b"
  (doc-from-site "a.com"))
