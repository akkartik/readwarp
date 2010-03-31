(let tree (decision-tree '("a" "b" "c" "d"))
  (each n '(0 1 2 3 4 5 6)
    (test-iso (+ "tree-choose " n " picks the " n "th option in a circular list")
      (tree (remainder n len.tree))
      (tree-choose tree n))))

(def tree-enumerate(tree l)
  (sort < (map [tree-choose tree _] l)))

(let tree (decision-tree '((0 1) (2 3) (4 5) (6 7)))
  (test-iso "tree-choose works over 2-level trees"
      '(0 1 2 3 4 5 6 7)
      (tree-enumerate tree '(0 1 2 3 4 5 6 7))))

(let tree (decision-tree '((0 1) 2 (4 5) 6))
  (test-iso "tree-choose is currently unfair over unbalanced 2-level trees"
      '(0 1 2 4 5 6)
      (dedup:tree-enumerate tree '(0 1 2 4 5 6 7 8 9))))

(let tree (decision-tree '((0 (1 2 (3 4 5)))))
  (test-iso "tree-choose eventually works over extremely unbalanced 3-level trees"
      '(0 1 2 3 4 5)
      (dedup:tree-enumerate tree '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17))))
