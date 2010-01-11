(load "utils.arc")

(init skip-list-max-height* 28)
(init skip-list-max-level* (- skip-list-max-height* 1))
(init skip-list-max* (expt 2 skip-list-max-height*))
(init skip-list-max-node*
   (obj val skip-list-max* height skip-list-max-level* next nil))

(def random-level()
  (ret n 0
    (while (and (< 0.5 (rand)) (<= n skip-list-max-level*))
      (++ n))))

(def slist()
  (obj height skip-list-max-height* next nils.skip-list-max-level*))

(def nils(n)
  (accum acc
    (repeat n (acc skip-list-max-node*))))

(def slnode(v)
  (let l (random-level)
    (obj val v height (+ l 1) next (nils (+ l 1)))))

(proc insert-sl(sl v)
  (fit-into sl slnode.v))

(mac loop-levels(var node . body)
  `(looplet ,var (- (,node 'height) 1)
                 (>= ,var 0)
                 (-- ,var)
      ,@body))

(proc fit-into(sl node)
;?   (prn "inserting " node!val " of height " node!height)
  (loop-levels l node
    (fit-level sl node l)))

(proc fit-level(sl node level)
;?   (prn " fitting level " level)
  (let n (scan sl node!val level)
    (= node!next.level n!next.level)
    (= n!next.level node)))

(def slen(sl)
  (ret ans 0
    (looplet n sl!next.0
               (no:is n skip-list-max-node*)
               (= n n!next.0)
      (++ ans))))

(proc prn-skip-list(sl)
  (looplet n sl!next.0
             (no:is n skip-list-max-node*)
             (= n n!next.0)
    (pr n!val ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

(proc prn-next-pointers(nd)
  (prn:map [_ 'val] nd!next))

(def find-sl(sl v)
  (with (n sl
         l (- skip-list-max-level* 1))
    (while (>= l 0)
      (= n (scan n v l))
      (-- l))
    (if (iso n!next.0!val v)
      n!next.0)))

; from nd on level l, prev of smallest node larger than value v
(def scan(nd v l)
  (ret n nd
    (while (> v n!next.l!val)
      (= n n!next.l))))
