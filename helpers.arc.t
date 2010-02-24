(test-iso "inline works given a url"
  "inline('id', 'http://example.com/get1?arg=bar');"
  (inline "id" "http://example.com/get1?arg=bar"))

(test-smatch "inline works given a function"
  "inline.'id', '/x\\?fnid=.*'.;"
  (inline "id" (fn(req) 3)))

(test-iso "confirm+inline works with url"
  "if(confirm('abc')){inline('id', 'http://example.com');}"
  (confirm "abc" (inline "id" "http://example.com")))

(test-smatch "confirm+inline works with fn"
  "if.confirm.'abc'...inline.'id', '/x\\?fnid=.*'.;."
  (confirm "abc" (inline "id" (fn(req) 3))))

(test-iso "check-with-user works"
  "'arg=' + confirm('foo?')"
  (check-with-user "foo?" "arg"))

(test-iso "check-with-user works with url"
  "inline('id', '/foo?' + 'arg=' + confirm('arg?'));"
  (inline "id"
          (+ "'/foo?' + "
             (check-with-user "arg?" "arg"))))

(test-smatch "check-with-user works with fn"
  "inline.'id', '/x\\?fnid=.*' . '&' . 'arg=' . confirm.'arg'..;"
  (inline "id"
          (+ (jsquotes:flink (fn(req) 3)) " + '&' + "
             (check-with-user "arg" "arg"))))



(test-iso "w/jslink+update works with simple commands :style and :onclick"
  "<a href=\"#\" style=\"foo\" onclick=\"bar\">a</a>"
  (tostring:w/jslink (update-dom :style "foo" :onclick "bar")
    (pr "a")))

(test-iso "w/jslink+update synthesizes onclick out of :with and :into"
  "<a href=\"#\" style=\"foo\" onclick=\"inline('id', 'bar');\">a</a>"
  (tostring:w/jslink (update-dom :into "id" :with "bar" :style "foo")
    (pr "a")))

