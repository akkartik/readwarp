(test-iso "alist-json handles empty lists"
  "{}"
  alist-json.nil)

(test-iso "alist-json handles strings"
  "{\"abc\": \"def\"}"
  (alist-json '(("abc" "def"))))

(test-iso "alist-json handles symbols"
  "{\"abc\": \"def\"}"
  (alist-json '((abc "def"))))

(test-iso "alist-json handles numbers"
  "{\"abc\": \"3\"}"
  (alist-json '((abc 3))))

(test-iso "alist-json handles multiple keys"
  "{\"abc\": \"3\", \"def\": \"foo\", \"xyz\": \"this has spaces\"}"
  (alist-json '((abc 3) (def foo) (xyz "this has spaces"))))
