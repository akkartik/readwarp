(test-iso "dlist creates a doubly linked list containing given elems"
    '(3 4 5)
    (dl-elems:dlist '(3 4 5)))

(= d (dlist))
(test-ok "dl-empty? works"
    (dl-empty? d))

(push-front d 3)
(test-iso "push-front on empty list works"
    '(3)
    dl-elems.d)

(test-iso "pop-back works on single-elem dlist"
    3
    (pop-back d))

(test-ok "dl-empty? works"
    (dl-empty? d))

(test-nil "pop-back on empty dlist works"
    (pop-back d))

(push-back d 3)
(test-iso "push-back on empty list works"
    '(3)
    dl-elems.d)

(test-iso "what's pushed from back can be popped from front"
    3
    (pop-front d))

(test-ok "dl-empty? works"
    (dl-empty? d))

(= d (dlist '(5)))
(push-front d 4)
(push-front d 3)
(push-back d 6)
(push-front d 2)
(test-iso "series of pop-backs works"
    '(6 5 4 3 2)
    (accum acc
      (until (dl-empty? d)
        (acc (pop-back d)))))

(= d (dlist '(5)))
(push-front d 4)
(push-front d 3)
(push-back d 6)
(push-front d 2)
(test-iso "series of pop-fronts works"
    '(2 3 4 5 6)
    (accum acc
      (until (dl-empty? d)
        (acc (pop-front d)))))

(= d (dlist '(45)))
(pushn d 44 3)
(test-iso "pushn works"
    '(44 45)
    dl-elems.d)

(test-nil "pushn returns nil when nothing is popped"
    (pushn d 43 3))

(test-is "pushn returns popped elem when it exists"
    45
    (pushn d 42 3))

(test-iso "pushn pops element"
    '(42 43 44)
    dl-elems.d)

(test-iso "serialize dlist works"
    '(dlist (42 43 44))
    (serialize (dlist '(42 43 44))))
(test-iso "unserialize undoes serialize"
    (dlist '(42 43 44))
    (unserialize:serialize (dlist '(42 43 44))))
