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
  ; occasionally fails because findg failed for 10 iterations
  (test-is "always is like only but reruns the generator until it succeeds"
    'd
    (always foo (randpos keys.a))))



(test-ok "random-new returns random element"
         (pos (random-new '(1 2 3) nil) '(1 2 3)))

(test-ok "random-new returns random new element"
         (pos (random-new '(1 2 3) '(2)) '(1 3)))

(test-is "random-new returns random new element satisfying pred"
         1
         (random-new '(1 2 3) '(3) odd))



(test-iso "make-rrand works"
          (list '(a b)
                (obj 0 'a 1 'b)
                (obj a (backoff 0 default-rrand-backoff*)
                     b (backoff 1 default-rrand-backoff*))
                2)
          (make-rrand '(a b)))

(test-iso "make-rrand works without args"
          (list nil
                (table)
                (table)
                0)
          (make-rrand))

(test-nil "rrand works for nil rrands"
          (rrand nil))

(test-nil "rrand works for empty rrands"
          (rrand:make-rrand))

(let rr (make-rrand '(a b))
  (test-iso "rrand-maybe-list works"
            '(a b)
            rrand-maybe-list.rr)

  (test-iso "rrand-len works"
            2
            rrand-len.rr)

  (add-rrand rr 'c)
  (test-iso "add-rrand works"
            3
            rrand-len.rr)

  (test-iso "added element is present"
            2
            (check-rrand rr 'c))

  (test-iso "present in random table"
           'c
           (rrand-random-table.rr (check-rrand rr 'c)))

  (test-iso "present in list"
            0
            (pos 'c rrand-maybe-list.rr))

  (del-rrand rr 'a)
  (test-nil "del-rrand works"
            (check-rrand rr 'a))

  (test-iso "del-rrand decrements length"
            2
            rrand-len.rr)

  (test-nil "deleted elem removed from random table"
            (pos 'a (vals rrand-random-table.rr))))

(let rr (make-rrand '(a b))
  (backoff-rrand rr 'a "abc" nil)
  (test-iso "backoff-rrand adds to backoff"
            '(0 2 ("abc"))
            (rrand-lookup-table.rr 'a))

  (backoff-rrand rr 'a "def" t)
  (test-nil "backoff-rrand a second time deletes"
            (check-rrand rr 'a))

  (test-iso "backoff-rrand updates length on delete"
            1
            rrand-len.rr)

  (test-iso "backoff-rrand updates lookup-table on delete"
            (obj b (backoff 1 default-rrand-backoff*))
            rrand-lookup-table.rr)

  (test-iso "backoff-rrand updates random-table on delete"
            (obj 1 'b)
            rrand-random-table.rr)

  (backoff-rrand rr 'b "abc" nil)
  (backoff-rrand rr 'b "abc" nil)
  (test-iso "backoff-rrand a second time backs off"
            2
            (len:backoff-attempts rrand-lookup-table.rr!b))

  (backoff-clear-rrand rr 'b)
  (test-iso "backoff-clear-rrand clears backoff"
            0
            (len:backoff-attempts rrand-lookup-table.rr!b))
  )
