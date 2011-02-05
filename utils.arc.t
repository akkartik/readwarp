(test-iso "string works on nil sym"
  ""
  (string nil))

(test-is "symize works on nil sym"
  nil
  (symize nil))



(let a 0
  (test-is "findg loops retrying generator until output satisfies predicate"
    2
    (findg (++ a) even))

  (test-is "findg - 2"
    3
    (findg (++ a) [is _ 3]))

  (test-is "findg - 3"
    9
    (findg (++ a) [is 18 (* _ 2)])))

(test-nil "findg returns nil on infinite loop"
  (findg 3 even))

(withs (a (obj 1 'a 3 'b 5 'c 6 'd)
        foo (fn(n)
              (if even.n
                a.n)))
  (test-is "always is like only but reruns the generator until it succeeds"
    'd
    (always foo (randpos keys.a))))



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



(let a '(1 2 3 4)
  (nslowrot a)
  (test-iso "nslowrot works"
    '(2 3 4 1)
    a)

  (wipe a)
  (nslowrot a)
  (test-iso "nslowrot works on empty lists"
    '()
    a)

  (push 3 a)
  (nslowrot a)
  (test-iso "nslowrot works on single lists"
    '(3)
    a)

  (push 2 a)
  (nslowrot a)
  (test-iso "nslowrot swaps 2-elem lists"
    '(3 2)
    a))

(test-ok "random-new returns random element"
         (pos (random-new '(1 2 3) nil) '(1 2 3)))

(test-ok "random-new returns random new element"
         (pos (random-new '(1 2 3) '(2)) '(1 3)))

(test-is "random-new returns random new element satisfying pred"
         1
         (random-new '(1 2 3) '(3) odd))

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

(test-ok "subseq? works"
  (subseq? '(1 3 5) '(1 2 3 4 5 6)))
(test-ok "subseq? handles empty sequence and pat"
  (subseq? '() '()))
(test-nil "subseq? handles empty sequence"
  (subseq? '(1 3 5) '()))
(test-ok "subseq? handles empty pat"
  (subseq? '() '(1 3 5)))
(test-ok "subseq? handles sequences identical to pat"
  (subseq? '(1 3 5) '(1 3 5)))
(test-ok "subseq? handles sequences that end at the same time as pat"
  (subseq? '(1 3 5) '(1 2 5 3 5)))
(test-nil "subseq? detects missing elem"
  (subseq? '(1 3 5) '(1 2 3 4 6)))
(test-ok "subseq? ignores order of other elems"
  (subseq? '(1 3 5) '(1 2 3 5 4 6)))
(test-nil "subseq? detects unordered elems in the subseq?uence"
  (subseq? '(1 3 5) '(1 2 5 3 4 6)))
(test-ok "subseq? ok's dup elems as long as one of them is in order"
  (subseq? '(1 3 5) '(1 2 5 3 5 4 6)))



(test-iso "freq initializes empty table"
          (table)
          (freq '()))

(test-iso "freq computes frequency table"
          (obj 1 3 2 1 3 2)
          (freq '(1 2 3 1 3 1)))

(test-is "max-freq works"
          1
          (max-freq '(1 2 3 1 3 1)))

(let a nil
  (test-iso "inittab returns table with values"
            (obj 1 2 3 4)
            (inittab a 1 2 3 4)))

(let a (obj 1 2)
  (inittab a 3 4)
  (test-iso "inittab retains preexisting values"
            (obj 1 2 3 4)
            a))

(let a (obj 1 2)
  (test-iso "inittab doesn't overwrite existing values"
            (obj 1 2 3 4)
            (inittab a 1 5 3 4)))

(with (a nil x 3)
  (inittab a x (+ x 1))
  (test-iso "inittab evaluates keys and values"
            (obj 3 4)
            a))

(with (inittab-test nil x 0)
  (def inittab-test()
    (w/table ans
      (or= ans.x (table))
      (or= ans.x.3 4)
      (or= ans.x!foo (table))
      (or= ans.x!bar (table))))

  (with (a (table) x 3 y 'bar)
    (test-iso "inittab handles quoted and unquoted keys"
              ((inittab-test) 0)
              (inittab a.0 x (+ 3 1) 'foo (table) y (table)))))



(test-iso "regexp-escape"
  "a\\+b"
  (regexp-escape "a+b"))

(test-iso "posmatchall"
  '(1 3 5)
  (posmatchall "b" "abcbdbe"))

(test-iso "split-urls tokenizes along punctuation"
  '("a" "com" "b")
  (split-urls "a.com/b"))

(test-iso "uncamelcase works"
  "Bay Area"
  (uncamelcase "BayArea"))

(test-iso "uncamelcase leaves unchanged if necessary"
  "Venture"
  (uncamelcase "Venture"))



(test-iso "aboutnmost should take top n"
  '(7 6)
  (aboutnmost 2 '(1 6 3 5 7)))

(test-iso "aboutnmost should not break ties"
  '((7 7) (6 6) (6 5))
  (aboutnmost 2 '((6 6) (1 1) (6 5) (3 3) (5 5) (7 7)) car))

(test-nil "aboutnmost should not return nils"
  (aboutnmost 2 '(() () () ())))

(test-is "pair? handles atoms"
  nil
  (pair? "abc"))

(test-is "pair? handles lists"
  t
  (pair? '(1 2)))

(test-is "pair? handles long lists"
  nil
  (pair? '(1 2 3 4)))

(test-iso "unserialize handles tables"
  (obj 1 2)
  (w/instring f "(table ((1 2)))" (unserialize:read f)))

(test-iso "unserialize handles nil"
  (table)
  (w/instring f "(table ())" (unserialize:read f)))

(test-iso "unserialize handles non-tables"
  '(1 2)
  (w/instring f "(1 2)" (unserialize:read f)))

(test-iso "unserialize handles strings"
  "abc"
  (w/instring f "\"abc\"" (unserialize:read f)))

(test-iso "unserialize handles compound non-tables"
  '(1 "abc")
  (w/instring f "(1 \"abc\")" (unserialize:read f)))

(test-iso "unserialize handles nested tables"
  (obj 1 "abc" 2 (obj 3 4))
  (w/instring f "(table ((1 \"abc\") (2 (table ((3 4))))))" (unserialize:read f)))

(test-iso "unserialize handles nested empty tables"
  (obj 1 2 3 (table))
  (w/instring f "(table ((1 2) (3 (table ()))))" (unserialize:read f)))

(test-iso "unserialize handles tables containing dlists"
  (obj 1 2 3 (dlist '(4)))
  (w/instring f "(table ((1 2) (3 (dlist (4)))))" (unserialize:read f)))

(test-iso "unserialize handles lists containing tables"
  (list 1 2 (table))
  (w/instring f "(1 2 (table ()))" (unserialize:read f)))

(test-iso "unserialize reverses serialize for integers"
  236
  (unserialize:serialize 236))

(test-iso "unserialize reverses serialize for strings"
  "abc"
  (unserialize:serialize "abc"))

(test-iso "unserialize reverses serialize for nil"
  ()
  (unserialize:serialize ()))

(test-iso "unserialize reverses serialize for lists"
  '(1 2 34)
  (unserialize:serialize '(1 2 34)))

(test-iso "unserialize reverses serialize for tables"
  (table)
  (unserialize:serialize (table)))

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
