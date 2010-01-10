(load "utils.arc")

(= skip-list-max-level* 28)
(= skip-list-max* (expt 2 (+ 1 skip-list-max-level*)))

(def random-level()
  (ret n 1
    (while (and (< 0.5 (rand)) (<= n skip-list-max-level*))
      (++ n))))

(def maxs(n)
  (let node (maxnode)
    (accum acc
      (repeat n (acc node)))))

(def maxnode()
  (obj val skip-list-max* height skip-list-max-level* next nil))

(def nils(n)
  (accum acc
    (repeat n acc.nil)))

(def slnode(v)
  (let h (random-level)
    (obj val v height h next nils.h)))

(def slist()
  (obj next maxs.skip-list-max-level*))

(def insert(sl v)
  (fit-into sl slnode.v))

(def fit-into(sl node)
;?   (prn "inserting " node!val " of height " node!height)
  (loop (= h node!height) (> h 0) (-- h)
    (fit-level sl node (- h 1))))

(def fit-level(sl node level)
;?   (prn " fitting level " level)
  (let n sl
    (while (> node!val n!next.level!val)
      (= n n!next.level))
    (= node!next.level n!next.level)
    (= n!next.level node)))
