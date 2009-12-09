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

(test-iso "defscan adds code to function to read fifo"
  '(def foo()
    (each-fifo doc "fifos/foo"
      (prn "foo" ": " doc)
      (do1 (do 0)
        nil)))
  (macex1:quote:defscan foo "foo" 0))

(test-iso "defscan optionally adds code to function to write next fifo"
  '(def foo()
    (each-fifo doc "fifos/foo"
      (prn "foo" ": " doc)
      (do1 (do 0)
        (fwrite "fifos/foo2" doc))))
  (macex1:quote:defscan foo "foo" "foo2" 0))
