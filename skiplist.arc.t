;? (= sl (slist))
;? 
;? (for n 0 (- skip-list-max-level* 1)
;?   (test-iso (if (is n 0) "initialize to one node pointing to maxnode" "")
;?     skip-list-max*
;?     sl!next.n!val))

(= freq (table))
(= freq2 (table))

(repeat 500
  (= sl (slist))
  (= h (insert-sl sl 32))
  (or= freq.h 0)
  (zap [+ _ slen.sl] freq.h)
  (or= freq2.h 0)
  (++ freq2.h))

prn.freq
prn.freq2

;?   (prn-skip-list sl))

;? (test-iso "insert updates level-0 pointer"
;?   32
;?   sl!next.0!val)

;? (prn "== Assuming inserted at a higher level")
;? (= sl (slist))
;? (scoped-extend random-level
;?   (def random-level() (+ 1 (rand 5)))
;? 
;?   (insert-sl sl 32)
;?   (prn-skip-list sl)
;?   (test-iso "insert updates level-0 pointer"
;?     32
;?     sl!next.0!val))
;? 
;? ;? (repeat 50
;? ;?   (insert-sl sl rand.1000))
;? ;? ;? (prn-skip-list sl)
;? ;? 
;? ;? (insert-sl sl 45)
;? ;? (test-is "find finds if exists"
;? ;?   45
;? ;?   (find-sl sl 45))
;? ;? 
;? ;? ;? (scoped-extend
