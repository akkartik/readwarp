(= sl (slist))

(for n 0 (- skiplist-max-level* 1)
  (test-iso (if (is n 0) "initialize to one node pointing to maxnode" "")
    skiplist-max*
    sl!next.n!val))



(mac insert-sl-at-level(n sl v)
  `(scoped-extend random-level (redef random-level (fn() ,n))
      (insert-sl ,sl ,v)))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level 0 sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert at level 0 always updates level-0 pointer"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level 1 sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert at level 1 always updates level-0 pointer"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl-at-level (+ 1 (rand (- skiplist-max-height* 1))) sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert at higher levels always updates level-0 pointer"
    0
    ans.nil))

(let ans (obj t 0 nil 0)
  (repeat 50
    (= sl (slist))
    (insert-sl sl 32)
    (++ (ans (is 32 sl!next.0!val))))
  (test-is "insert always updates level-0 pointer"
    0
    ans.nil))



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
(test-is "find - stress test"
  45
  ((find-sl sl 45) 'val))

(def sl-rand(sl)
  (let n sl!next.0
    (repeat rand.30
      (= n (n!next (rand n!height))))
    n!val))



(disabled ; for speed
  (prn "Building a skiplist for performance test")
  (= sl (slist))
  (repeat 5000
    (insert-sl sl rand.5000))
  (prn "Ready " slen.sl " elems")

  (scoped-extend scan
    (= travs* 0)
    ; XXX: hook into existing def
    (redef scan
      (fn(nd v l)
        (ret n nd
          (while (> v n!next.l!val)
            (++ travs*)
            (= n n!next.l)))))

    (repeat 10
      (redef travs* 0)
      (let val rand.5000 ; (read) ; sl-rand.sl
        (aif (find-sl sl val)
          (pr " found! " it!val " at " (sl-index sl it!val) ": ")
          (pr " not found! "))
        (prn travs* " traversals")))))



(prn "   ---- skip lists with transformer function")

(= sl (slist len))
(insert-sl sl "abc")
(test-iso "inserts with transformer can be found"
  "abc"
  ((find-sl sl "abc") 'val))

(prn "   -- ties now possible: non-identical values with the same metric")
; Fixture. heights [tied elements]: 3 [1 1 3 2 1 2 1 3]
(= sl (slist len))
(insert-sl-at-level 2 sl "a")
(insert-sl-at-level 2 sl "aaa")
(insert-sl-at-level 0 sl "baa")
(insert-sl-at-level 1 sl "aba")
(insert-sl-at-level 0 sl "caa")
(insert-sl-at-level 1 sl "aca")
(insert-sl-at-level 2 sl "aab")
(insert-sl-at-level 0 sl "daa")
(insert-sl-at-level 0 sl "eaa")

(test-iso "find can find the first tied value"
  "eaa"
  ((find-sl sl "eaa") 'val))

(test-iso "find can find the first tied value at any level"
  "aab"
  ((find-sl sl "aab") 'val))

(test-iso "find can find later tied values at higher levels"
  "aaa"
  ((find-sl sl "aaa") 'val))

(test-iso "find can backtrack back to lower levels when not found at higher levels"
  "daa"
  ((find-sl sl "daa") 'val))


(= sl (slist len))
(insert-sl sl "abd")

(test-ok "find doesn't return wrong values"
  (~find-sl sl "a"))

(test-ok "find doesn't return wrong but tied values"
  (~find-sl sl "abc"))


(disabled
  (= sl (slist [remainder _ 571]))
  (repeat 500
    (insert-sl sl rand.5000))
  (prn-sl sl))



(= sl (slist len))
(insert-sl sl "abc")
(test-ok "" (~is sl!next.0 skiplist-max-node*))
(delete-sl sl "abc")
(test-is "delete works on first element"
  skiplist-max-node*
  sl!next.0)

(insert-sl sl "a")
(insert-sl sl "aaa")
(insert-sl sl "aa")
(insert-sl sl "aaaa")
(delete-sl sl "aa")
(test-iso "delete works on later element"
  "aaa"
  sl!next.0!next.0!val)

(prn "   -- deletion in the presence of ties")
(= sl (slist len))
(insert-sl sl "a")
(insert-sl sl "b")
(insert-sl sl "c")
(prn "before:")
(prn-sl sl)
(delete-sl sl "b")
(prn "after deleting b:")
(prn-sl sl)
(test-ok "delete handles ties in the metric" (~find-sl sl "b"))

(let old-len slen.sl
  (delete-sl sl "z")
  (test-is "delete doesn't delete other values" old-len slen.sl))

(test-iso "best-sl returns first elem by default"
  "c"
  (best-sl sl))

(test-iso "best-sl returns first elem satisfying pred"
  "a"
  (best-sl sl [iso "a" _]))

(test-ok "best-sl returns nil when not found"
  (~best-sl sl (fn(x) nil)))
