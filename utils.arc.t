(test-is "blet is let when post-condition is satisfied"
  (let n 2
    (++ n))
  (blet n 2 t
    (++ n)))

(test-is "blet returns init if post-condition fails"
  2
  (blet n 2 nil
    (++ n)))

(test-is "blet backtracks body if post-condition not satisfied"
  2
  (blet n 2 (even n)
    (++ n)))



(with (a nil b nil)
  (def a() 3)
  (def b() (a))

  (scoped-extend a
    (def a() 2)
    (test-is "scoped-extend dynamically overrides var"
      2
      (b)))

  (test-is "functions unchanged outside scoped-extend"
    3
    (b)))



(test-iso "extract-car extracts car if it matches type"
  '("a" ((prn a) (+ 1 1)))
  (extract-car '("a" (prn a) (+ 1 1)) 'string))

(test-iso "extract-car doesn't extract car if it doesn't match type"
  '(nil (a (prn a) (+ 1 1)))
  (extract-car '(a (prn a) (+ 1 1)) 'string))

(test-iso "extract-car extracts car if it satisfies predicate"
  '(3 ((prn a) (+ 1 1)))
  (extract-car '(3 (prn a) (+ 1 1)) [errsafe:> _ 0]))

(test-iso "extract-car doesn't extract car if it doesn't match type"
  '(nil (3 (prn a) (+ 1 1)))
  (extract-car '(3 (prn a) (+ 1 1)) [errsafe:_ 0]))



(test-iso "test* generates test for fn"
  2
  ((test* [+ _ 2]) 0))

(test-iso "test* generates test for type"
  t
  ((test* 'int) 0))

(test-iso "test* compares by default"
  t
  (test*.34 34))

(test-iso "test* compares by default"
  nil
  (test*.33 34))



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

(test-iso "sliding-window"
          '((1 2) (2 3) (3))
          (sliding-window 2 '(1 2 3)))

(test-iso "sliding-window trivial"
          '((1))
          (sliding-window 2 '(1)))



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

(test-iso "set works"
  (obj a t b t)
  (Set 'a 'b))



(test-iso "normalized-affinity-table works on 2-element clusters"
  (obj
    "a" (obj "b" 1.0)
    "b" (obj "a" 1.0))
  (normalized-affinity-table (obj dummy '("a" "b"))))

(test-iso "normalized-affinity-table distributes weight across large clusters"
  (obj
    "a" (obj "b" 0.5 "c" 0.5)
    "b" (obj "a" 0.5 "c" 0.5)
    "c" (obj "a" 0.5 "b" 0.5))
  (normalized-affinity-table (obj dummy '("a" "b" "c"))))

(test-iso "normalized-affinity-table adds weights from different clusters"
  (obj
    "a" (obj "b" 1.0)
    "b" (obj "a" 1.0 "c" 1.0)
    "c" (obj "b" 1.0))
  (normalized-affinity-table (obj x1 '("a" "b") x2 '("b" "c"))))

(let a (normalized-affinity-table (obj x1 '("a" "b") x2 '("b" "c")))
  (test-is "reflexive affinities never exist"
    nil
    ((a "a") "a")))



(let global* 34
  (def abc-test-fn()
    (++ global*))

  (test-is "" global* 34)
  (abc-test-fn)
  (test-is "" global* 35)

  (let global* 3
    (abc-test-fn)
    (test-is "" global* 3))

  (test-is "" global* 36)
  (shadow global* 3)
  (test-is "shadow creates a dynamic scope"
    3
    global*)
  (abc-test-fn)
  (test-is "" global* 4)

  (unshadow global*)
  (test-is "unshadow restores old binding"
    36
    global*)

  (= a '(1 2 3))
  (= b a)
  (shadow a '(1 2 3))
  (push 3 a)
  (test-iso "shadow allows destructive updates"
    '(3 1 2 3)
    a)
  (test-iso "shadow leaves other variables accessible"
    '(1 2 3)
    b)
  (push 4 b)
  (unshadow a)
  (test-iso "unshadow loses changes to lists"
    '(1 2 3)
    a)

  (= a 34)
  (= b a)
  (shadow a '(1 2 3))
  (++ b)
  (unshadow a)
  (test-iso "unshadow loses changes to primitives"
    34
    a)

  (= a (obj 1 2 3 4))
  (= b a)
  (shadow a '(1 2 3))
  (= (b 5) 6)
  (unshadow a)

  (test-iso "unshadow doesn't lose changes to tables"
    (obj 1 2 3 4 5 6)
    a))
