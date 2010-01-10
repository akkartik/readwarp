(load "utils.arc")

(= proc def)

(init skip-list-max-level* 28)
(init skip-list-max* (expt 2 (+ 1 skip-list-max-level*)))
(init skip-list-max-node*
   (obj val skip-list-max* height skip-list-max-level* next nil))

(def random-level()
  (ret n 1
    (while (and (< 0.5 (rand)) (<= n skip-list-max-level*))
      (++ n))))

(def slist()
  (obj next nils.skip-list-max-level*))

(def nils(n)
  (accum acc
    (repeat n (acc skip-list-max-node*))))

(def slnode(v)
;?   (prn "slnode")
  (let h (random-level)
;?     (prn " height " h)
    (obj val v height h next nils.h)))

(proc insert-sl(sl v)
  (fit-into sl slnode.v))

(mac height-loop(var node . body)
  `(loop (= ,var (- (len (,node 'next)) 1)) (> ,var 0) (>= h 0) (-- h)
      ,@body))

(proc fit-into(sl node)
;?   (prn "height " node!height)
;?   (prn "inserting " node!val " of height " node!height)
  (height-loop h node
    (fit-level sl node h))
  node!height)

(proc fit-level(sl node level)
;?   (prn " fitting level " level)
  (let n (scan sl node!val level)
    (= node!next.level n!next.level)
    (= n!next.level node)))

(def slen(sl)
  (ret ans 0
    (looplet n sl!next.0 (no:is n skip-list-max-node*) (= n n!next.0)
      (++ ans))))

(proc prn-skip-list(sl)
  (prn "- skiplist")
  (looplet n sl!next.0 (no:is n skip-list-max-node*) (= n n!next.0)
    (pr n!val ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

;? (def find-sl(sl v)
;?   (with (n sl
;?          curr-level skip-list-max-level*)
;?     (while (> v n!next.curr-level!val)
;?       (= n n!next.curr-level))
;?     (if (iso v n!next.curr-level!val)
;?       n!next.curr-level
;?       (recurse n!next.curr-level (- curr-level 1))

;? ; scan from node on level l for value v
;? (def find-sub(node l v)
;?   (let n node
;?     (while (> v node!next.l)
;?       (= n!next.level))
;?     n)

(def scan(node val level)
  (let n node
    (while (> val n!next.level!val)
      (= n n!next.level))
    n))
