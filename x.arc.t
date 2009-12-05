(include "arctap.arc")

(include "x.arc")

(test-iso "set works"
  (obj a t b t)
  (Set 'a 'b))

(= docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a")
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b")
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0")
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

(= userinfo*
    (obj
      0 (obj read (table))))

(ok (no:current-user-read "a_com_a"))

(test-iso "site-docs should return docs from same site"
  '("a_com_a" "a_com_b" "a_com_c")
  (sort < (site-docs "a.com")))

(= userinfo*
    (obj
      0 (obj read (Set "a_com_a"))))

(ok (current-user-read "a_com_a"))

(test-iso "site-docs should return unread docs"
  '("a_com_b" "a_com_c")
  (sort < (site-docs "a.com")))

(ok (no:current-user-read (random-unread)) "random-unread should return an unread doc")

(test-iso "feed-docs should return unread docs from same feed"
  '("a_com_c" "b_com_0")
  (sort < (feed-docs "a.com/feed2")))

(= doc-generators* (list site-docs feed-docs))
(test-iso "gen-docs should return superset of site-docs and feed-docs"
  '("a_com_b" "a_com_c" "b_com_0")
  (sort < (gen-docs "a.com/c")))

(= docinfo*
    (obj
      "a_com_a" (obj site "a.com" feed "a.com/feed" url "a.com/a" keywords '("a" "b" "c"))
      "a_com_b" (obj site "a.com" feed "a.com/feed" url "a.com/b" keywords '("a"))
      "a_com_c" (obj site "a.com" feed "a.com/feed2" url "a.com/c")
      "b_com_0" (obj site "b.com" feed "a.com/feed2" url "b.com/0" keywords '("a"))
      "b_com_a" (obj site "b.com" feed "b.com/feed" url "b.com/a")))

(= index*
  (obj
    "a" '("a_com_a" "a_com_b" "b_com_a")
    "b" '("a_com_a")
    "c" '("a_com_a")))

(= doc-generators* (list site-docs feed-docs keywords-docs))
(test-iso "gen-docs should include docs with keyword overlap"
  '("a_com_b" "a_com_c" "b_com_0" "b_com_a")
  (sort < (gen-docs "b.com/0")))
