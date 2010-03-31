(= decision-tree id)

(= decision-forest id)

(def foo(n N)
  (/ n N))

(def tree-choose(tree n)
;?   (erp tree " -- " n " " (foo n len.tree) " " (floor:foo n len.tree))
  (if
    (no tree)
        nil
    (~acons tree)
        tree
      (tree-choose (tree (remainder n len.tree)) (floor:foo n len.tree))))
