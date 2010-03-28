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



(test-ok "random-new returns random element"
         (pos (random-new '(1 2 3) nil) '(1 2 3)))

(test-ok "random-new returns random new element"
         (pos (random-new '(1 2 3) '(2)) '(1 3)))

(scoped-extend random-new
  (after-exec random-new(from to f)
    (prn result))

  (test-is "random-new returns random new element satisfying pred"
           1
           (random-new '(1 2 3) '(3) odd))
)



(test-iso "make-rrand works"
          (list (obj 0 'a 1 'b) 2)
          (make-rrand '(a b) (table) 0))
