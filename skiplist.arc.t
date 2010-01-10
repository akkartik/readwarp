(= sl (slist))

(for n 0 (- skip-list-max-level* 1)
  (test-iso (if (is n 0) "initialize to one node pointing to maxnode" "")
    skip-list-max*
    sl!next.n!val))

(insert sl 32)
(test-iso "insert updates level-0 pointer"
  32
  sl!next.0!val)
