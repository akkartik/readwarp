(= sl (slist))

(for n 0 (- skip-list-max-level* 1)
  (test-iso (if (is n 0) "initialize to one node pointing to maxnode" "")
    skip-list-max*
    sl!next.n!val))

(insert-sl sl 32)
(test-iso "insert updates level-0 pointer"
  32
  sl!next.0!val)

(repeat 50
  (insert-sl sl rand.1000))
;? (prn-skip-list sl)

;? (insert-sl sl 45)
;? (test-is "find finds if exists"
;?   45
;?   (find-sl sl 45))

;? (scoped-extend
