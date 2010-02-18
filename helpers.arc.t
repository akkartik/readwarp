(test-iso "w/jslink+update works with simple commands :style and :onclick"
  "<a href=\"#\" style=\"foo\" onclick=\"bar\">a</a>"
  (tostring:w/jslink (update-dom :style "foo" :onclick "bar")
    (pr "a")))

(test-iso "w/jslink+update synthesizes onclick out of :with and :into"
  "<a href=\"#\" style=\"foo\" onclick=\"inline('id', 'bar')\">a</a>"
  (tostring:w/jslink (update-dom :into "id" :with "bar" :style "foo")
    (pr "a")))
