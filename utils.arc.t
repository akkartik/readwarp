(test-iso "tags-matching should return cdrs of dotted pairs whose cars satisfy"
          '(3 6)
          (tags-matching 2 '((1 . 2) (2 . 3) (4 . 5) (2 . 6))))

(test-iso "zip should work on simple lists"
          '((1 2) (2 4) (3 6))
          (zip '(1 2 3) '(2 4 6)))

(test-iso "zip should work on asymmetric lists"
          '((1 2) (2 4) (3 6))
          (zip '(1 2 3) '(2 4 6 7)))

(test-iso "zip should work on any number of lists"
          '((1 2 3) (2 4 6) (3 6 9))
          (zip '(1 2 3) '(2 4 6 7) '(3 6 9)))

(test-iso "zipmax should return as many elements as the longest list"
          '((1 2) (2 4) (3 6) (nil 7))
          (zipmax '(1 2 3) '(2 4 6 7)))

(test-iso "cdrs"
          '((1 2 3) (2 3) (3))
          (cdrs 2 '(1 2 3)))

(test-iso "nctx"
          '((1 2) (2 3) (3 nil))
          (nctx 2 '(1 2 3)))

(test-iso "nctx trivial"
          '((1 nil))
          (nctx 2 '(1)))

(test-iso "partition-words should partition along whitespace"
          '("abc" " " "def")
          (partition-words "abc def"))

(test-iso "partition-words should partition along punctuation"
          '("abc" ", " "def")
          (partition-words "abc, def"))

(test-iso "partition-words should intelligently partition along punctuation 1"
          '("abc" " - " "def")
          (partition-words "abc - def"))

(test-iso "partition-words should intelligently partition along punctuation 2"
          '("abc-def")
          (partition-words "abc-def"))

(test-iso "partition-words should intelligently partition along punctuation 3"
          '("abc" " \"" "def" "\"")
          (partition-words "abc \"def\""))

(test-iso "partition should partition strings by whitespace by default"
  '("0a" " " "bcdef" " " "g")
  (partition "0a bcdef g"))

(test-iso "regexp-escape"
  "a\\+b"
  (regexp-escape "a+b"))

(test-iso "r-strip works like gsub on pairs"
  "abc"
  (r-strip "abc<def>" "<.*>"))

(test-iso "r-strip finds shortest matches"
  "abc"
  (r-strip "<boo abc</boo>abc<boo def</boo>" "<boo .*</boo>"))

(test-iso "splitstr splits at occurrences of pat"
  '("abc" "def")
  (splitstr "abc foo def" " foo "))

(test-iso "splitstr splits at occurrences of pat"
  '("a" "c" "d" "e")
  (splitstr "abcbdbe" "b"))

(test-iso "posmatchall"
  '(1 3 5)
  (posmatchall "b" "abcbdbe"))

(test-iso "aboutnmost should take top n"
  '(7 6)
  (aboutnmost 2 '(1 6 3 5 7)))

(test-iso "aboutnmost should not break ties"
  '((7 7) (6 6) (6 5))
  (aboutnmost 2 '((6 6) (1 1) (6 5) (3 3) (5 5) (7 7)) car))

(test-iso "aboutnmost should not return nils"
  '()
  (aboutnmost 2 '(nil nil nil nil)))

(test-is "pair? handles atoms"
  nil
  (pair? "abc"))

(test-is "pair? handles lists"
  t
  (pair? '(1 2)))

(test-is "pair? handles long lists"
  nil
  (pair? '(1 2 3 4)))

(test-iso "coerce-tab leaves tables as-is"
  (obj a 1 b 2)
  (coerce-tab (obj a 1 b 2)))

(test-iso "coerce-tab converts tablists"
  (obj a 1 b 2)
  (coerce-tab '((a 1) (b 2))))

(test-iso "coerce-tab converts non-tablist lists"
  (obj a 1 b 2)
  (coerce-tab '(a 1 b 2)))

(test-iso "coerce-tab converts nil to empty table"
  (table)
  (coerce-tab ()))

(test-iso "merge-tables works on tables"
  (obj a 1 b 2)
  (merge-tables (obj a 1) (obj b 2)))

(test-iso "merge-tables overrides in sequence"
  (obj a 1 b 2)
  (merge-tables (obj a 1 b 1) (obj b 2)))

(test-iso "merge-tables converts to tables if necessary"
  (obj a 1 b 2)
  (merge-tables '(a 1 b 1) (obj b 2)))

(test-is "alist? detects lists of pairs"
  t
  (alist? '((1 2) (3 4))))

(test-is "nil is not an alist"
  nil
  (alist? nil))

(test-is "alist? doesn't falsely detect two-character strings"
  nil
  (alist? '((1 2) "ab")))
