(load "utils.arc")

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
  (let h (random-level)
    (obj val v height h next nils.h)))

(proc insert-sl(sl v)
  (fit-into sl slnode.v))

(mac loop-height(var node . body)
  `(loop (= ,var (- (len (,node 'next)) 1)) (> ,var 0) (>= h 0) (-- h)
      ,@body))

(proc fit-into(sl node)
  (loop-height h node
    (fit-level sl node h)))

(proc fit-level(sl node level)
  (let n sl
    (while (> node!val n!next.level!val)
      (= n n!next.level))
    (= node!next.level n!next.level)
    (= n!next.level node)))

(proc prn-skip-list(sl)
  (looplet n sl!next.0 (no:is n skip-list-max-node*) (= n n!next.0)
    (pr n!val ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

;? (def find-sl(sl v)
;?   (loop-height h 
;?   (loop (= h (len sl!next)) (h > 0) (-- h)
;?     (
