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
  '(do
    (init foo-log* ())
    (def foo()
      (prn "foo" " watching fifos/" "foo")
      (forever:each doc (tokens:slurp "fifos/foo")
        (rotlog foo-log* doc)
        (do1 (do 0)
          nil)))
    (init foo-thread* (new-thread foo)))
  (macex1:quote:defscan foo "foo" 0))

(test-iso "defscan optionally adds code to function to write next fifo"
  '(do
    (init foo-log* ())
    (def foo()
      (prn "foo" " watching fifos/" "foo")
      (forever:each doc (tokens:slurp "fifos/foo")
        (rotlog foo-log* doc)
        (do1 (do 0)
          (fwrite "fifos/foo2" doc))))
    (init foo-thread* (new-thread foo)))
  (macex1:quote:defscan foo "foo" "foo2" 0))

(defcmemo add-foo(a b) 'test-add
  (+ a b))

(test-iso "do-cmemo returns its body"
  2
  (do-cmemo 'test-add
    (add-foo 1 1)))

(do
  (do-cmemo 'test-add
    (add-foo 1 1))
  (test-iso "do-cmemo clears appropriate cmemo-cache when done"
    nil
    cmemo-cache*!test-add))
