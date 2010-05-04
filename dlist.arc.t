(test-iso "dlist creates a doubly linked list containing given elems"
    '(3 4 5)
    (dl-elems:dlist '(3 4 5)))

(= d (dlist))
(test-ok "dl-empty? works"
    (dl-empty? d))

(prn dl-len.d)
(push-front d 3)
(test-iso "push-front on empty list works"
    '(3)
    (dl-elems d))

(prn dl-len.d)
(test-iso "pop-back works on single-elem dlist"
    3
    (pop-back d))

(prn dl-len.d)
(test-ok "dl-empty? works"
    (dl-empty? d))

(prn dl-len.d)
(test-nil "pop-back on empty dlist works"
    (pop-back d))

(prn dl-len.d)
(push-back d 3)
(test-iso "push-back on empty list works"
    '(3)
    (dl-elems d))

(prn dl-len.d)
(test-iso "what's pushed from back can be popped from front"
    3
    (pop-front d))

(prn dl-len.d)
(test-ok "dl-empty? works"
    (dl-empty? d))

(= d (dlist '(5)))
(prn dl-len.d)
(push-front d 4)
(prn dl-len.d)
(push-front d 3)
(prn dl-len.d)
(push-back d 6)
(prn dl-len.d)
(push-front d 2)
(test-iso "series of pop-backs works"
    '(6 5 4 3 2)
    (accum acc
      (until (dl-empty? d)
        (prn dl-len.d)
        (acc (pop-back d)))))
(prn dl-len.d)

(= d (dlist '(5)))
(prn dl-len.d)
(push-front d 4)
(prn dl-len.d)
(push-front d 3)
(prn dl-len.d)
(push-back d 6)
(prn dl-len.d)
(push-front d 2)
(test-iso "series of pop-fronts works"
    '(2 3 4 5 6)
    (accum acc
      (until (dl-empty? d)
        (prn dl-len.d)
        (acc (pop-front d)))))
(prn dl-len.d)
