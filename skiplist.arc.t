(= sl (slist))

(for n 0 (- skip-list-max-level* 1)
  (test-iso (if (is n 0) "initialize to one node pointing to maxnode" "")
    skip-list-max*
    sl!next.n!val))



(mac insert-sl-at-level(n sl v)
  `(scoped-extend random-level (redef random-level (fn() ,n))
      (insert-sl ,sl ,v)))

(= sl (slist))
(insert-sl-at-level 0 sl 32)
(test-is "insert to level 0 updates level-0 pointer"
  32
  sl!next.0!val)

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert always updates level-0 pointer"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level 0 sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert always updates level-0 pointer at level 0"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level 1 sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert always updates level-0 pointer at level 1"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level 2 sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert always updates level-0 pointer at level 2"
    0
    ans.nil))

(prn "       rerun: insert at a higher level")
(= sl (slist))
(insert-sl-at-level 4 sl 32)
(test-is ""
  32
  sl!next.0!val)



(= sl (slist))
(insert-sl-at-level 1 sl 45)
(test-is "find - trivial case"
  45
  ((find-sl sl 45) 'val))

(= sl (slist))
(insert-sl-at-level 2 sl 32)
(insert-sl-at-level 2 sl 45)
(test-is "find - not first elem"
  45
  ((find-sl sl 45) 'val))

(= sl (slist))
(insert-sl-at-level 1 sl 32)
(insert-sl-at-level 1 sl 45)
(test-is "find - not first elem on level 1"
  45
  ((find-sl sl 45) 'val))

(= sl (slist))
(repeat 500
  (insert-sl sl rand.5000))

(insert-sl sl 45)
(test-is "find finds if exists"
  45
  ((find-sl sl 45) 'val))
