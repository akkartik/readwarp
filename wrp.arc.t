(test-is "nexthashchar is a ring from a-zA-Z0-9 - 1"
  #\b
  (nexthashchar #\a))
(test-is "nexthashchar is a ring from a-zA-Z0-9 - 2"
  #\A
  (nexthashchar #\z))
(test-is "nexthashchar is a ring from a-zA-Z0-9 - 3"
  #\0
  (nexthashchar #\Z))
(test-is "nexthashchar is a ring from a-zA-Z0-9 - 4"
  #\a
  (nexthashchar #\9))
(test-is "nexthashchar is a ring from a-zA-Z0-9 - 5"
  #\m
  (nexthashchar #\l))

(test-is "nexthash increments in the a-zA-Z0-9 ring - 1"
  "ab"
  (nexthash "aa"))
(test-is "nexthash increments in the a-zA-Z0-9 ring - 2"
  "3A"
  (nexthash "3z"))
(test-is "nexthash increments in the a-zA-Z0-9 ring - 3"
  "4a"
  (nexthash "39"))
(test-is "nexthash increments in the a-zA-Z0-9 ring - 4"
  "aa"
  (nexthash "99"))
