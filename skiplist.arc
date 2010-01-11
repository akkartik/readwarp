(load "utils.arc")

(init skip-list-max-height* 28)
(init skip-list-max-level* (- skip-list-max-height* 1))
(init skip-list-max* (expt 2 skip-list-max-height*))
(init skip-list-max-node*
   (obj val skip-list-max* height skip-list-max-level* next nil))

(= random-level-seed
  '(4 0 1 0 1 0 0 4 2 1 2 0 1 3 0 2 1 1 3 3 1 0 1 1 1 0 0 1 0 0 1 1 0 0 0 0 0 4 0 1 0 1 1 0 0 0 0 2 0 0 2 3 0 0 0 3 0 0 1 0 0 1 0 1 1 1 0 0 1 5 0 0 0 1 1 2 0 1 1 0 1 1 3 1 2 0 0 0 0 0 0 0 1 1 1 0 0 5 0 0 0 1 3 0 4 0 1 0 1 0 3 2 4 1 1 1 0 1 0 0 3 0 3 1 0 0 1 0 1 0 0 1 1 1 0 0 0 6 3 0 1 0 0 0 0 0 2 3 1 0 0 0 0 4 3 0 0 2 0 1 1 2 1 1 2 1 1 2 0 6 2 0 0 2 0 0 0 0 1 2 0 0 0 0 1 1 1 0 0 0 1 2 0 2 0 0 1 0 0 0 1 1 0 0 0 2 0 5 0 1 1 0 0 2 0 0 0 4 3 0 0 0 0 0 2 0 1 0 1 0 1 0 1 3 0 0 0 1 0 2 2 1 1 2 2 0 0 2 0 2 1 0 1 1 0 1 1 0 0 0 0 0 1 1 1 1 0 6 1 0 1 0 0 0 0 0 1 0 0 1 1 1 3 1 2 0 2 1 1 0 0 0 0 1 7 1 0 2 1 1 1 2 0 0 1 0 0 1 0 0 0 1 1 0 1 0 3 0 0 1 1 3 0 0 0 5 0 1 0 0 1 2 2 3 2 0 2 0 0 1 1 0 2 0 1 2 5 1 0 0 0 5 2 1 0 0 2 0 0 0 0 1 3 0 0 0 2 3 1 0 2 0 0 1 2 1 1 0 0 1 1 1 0 1 1 2 0 0 5 3 1 3 0 0 1 2 1 0 1 2 1 0 1 0 0 1 4 4 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 1 4 0 0 4 1 3 0 1 0 0 0 0 1 1 0 1 0 1 0 6 0 0 4 0 2 0 2 0 1 0 0 1 0 0 3 0 0 1 3 0 0 0 1 0 2 0 1 0 0 1 0 0 2 0 0 0 0 5 0 3 0 0 0 0 0 2 0 1 2 1 1 0 1 0 2 0 0 0 0 0 3 5 0 3 0 1 2 0 0 1 0 0 1 1 0 0 0 2 3 0 0 1 0 1 1 2 1 2 2 0 1 2 2 0 0 1 1 0 3 1 0 1 1 1 0 2 0 0 1 0 0 2 0 0 0 5 2 5 0 0 2 0 0 0 1 3 0 2 2 3 1 0 0 1 0 0 1 0 0 1 5 3 7 1 1 0 1 0 0 1 0 1 0 2 0 1 0 0 0 0 2 1 1 2 0 1 2 1 1 6 0 0 0 1 0 2 0 0 4 1 1 2 1 0 0 1 2 1 2 0 4 3 1 0 8 2 1 3 2 1 0 1 1 1 0 1 0 0 0 5 2 2 0 1 0 0 0 0 2 1 0 0 0 0 4 0 0 0 0 1 0 0 0 4 4 2 0 1 3 2 0 1 2 0 0 0 0 0 0 1 1 0 2 2 1 1 1 2 0 0 5 0 0 1 4 1 0 0 0 1 0 0 5 0 2 1 2 1 0 0 0 0 2 0 1 0 2 0 1 1 0 1 3 1 2 0 1 0 0 0 0 4 0 2 0 2 1 0 0 0 0 0 0 1 0 1 0 0 0 1 0 0 3 1 0 0 1 0 0 0 1 1 0 0 0 0 0 3 0 1 1 0 1 2 0 1 0 1 0 0 1 1 1 1 0 0 4 0 1 0 2 2 0 0 0 1 2 1 5 1 3 0 5 1 2 1 0 0 0 0 1 0 1 1 3 3 3 0 1 2 1 0 0 0 1 1 1 0 2 0 0 1 0 1 4 0 0 5 0 0 2 1 0 0 1 3 1 0 3 0 0 0 1 3 4 0 0 1 2 1 0 2 0 2 2 2 1 1 4 0 1 0 2 0 2 1 1 0 0 0 0 5 0 1 2 6 0 0 2 2 1 1 0 0 0 0 0 1 0 2 1 0 5 6 0 0 0 0 1 4 0 3 0 0 0 2 5 1 4 0 1 0 1 0 4 2 2 1 1 3 4 0 0 0 0 4 0 1 0 0 0 1 3 0 0 1 1 7 0 1 0 0 0 2 1 4 0 1 0 2 0 0 0 0 1 1 1 0 2 0 3 1 0 0 1 1 0 1 2 0 0 0 0 1 2 1 1 0 3 0 0 0 1 1 0 0 4 0 3 0 0 1 3 1 0 1 0 1 1 0 0 2 2 1 4 1 2 0 12 0 0 1 2 3 0 0 0 0 1 0 0 3 2 0 0 1 1 0 0 1 1 6 0 3 2 0 2 3 0 1 2 1 1 0 0 4 1 1 0 1 0 2 3 0 3 3 0 0 1 0 0 0 0 1 3 2 0 1 0 0 0 0 0 3 0 1 0 5 0 0 0 0 0 0 6 0 3 1 1 1 0 8 1 0 0 0 1 1 4 0 1 3 0 3 0 0 2 0 2 1 0 2 3 8 0 0 3 1 0 1 0 1 0 2 0 1 4 5 1 0 0 0 2 3 1 1 0 1 0 1 1 2 0 0 0 1 0 2 0 0 2 0 0 0 0 0 1 2 4 0 2 0 1 0 1 0 0 3 0 1 1 1 0 4 1 1 0 0 0 3 0 3 1 2 4 1 4 0 0 0 1 0 0 2 0 1 5 1 0 0 0 2 0 1 2 2 1 0 1 4 0 0 2 3 4 0 1 4 2 0 0 0 3 0 0 2 1 0 3 4 2 0 1 0 0 0 0 1 0 0 1 0 1 1 1 0 0 2 0 0 0 0 3 0 2 1 0 1 1 2 3 0 0 1 4 1 3 1 0 2 0 0 1 2 1 0 1 0 2 0 0 0 0 0 1 0 1 3 4 0 3 0 0 1 1 2 3 2 2 1 1 4 1 0 1 0 0 0 0 0 6 0 2 0 0 1 0 0 0 4 0 0 0 0 0 0 0 0 1 0 2 0 1 0 6 2 0 0 0 0 1 1 0 1 1 0 2 0 2 0 0 2 4 0 0 2 0 1 0 0 0 1 0 0 0 1 0 0 2 1 0 0 2 1 0 0 0 3 2 0 1 6 3 0 0 1 1 0 1 2 0 2 0 0 0 0 1 0 2 0 3 2 0 2 0 0 1 0 1 0 4 0 3 1 0 2 1 1 0 1 0 0 0 0 0 2 0 0 1 1 0 0 1 0 1 1 6 1 1 0 1 0 3 2 0 2 1 3 3 0 2 0 1 2 0 5 3 4 0 0 4 1 0 0 0 1 0 1 0 2 1 2 0 1 0 0 5 0 0 1 1 4 0 1 7 2 1 0 1 0 2 0 1 0 1 2 7 0 1 1 0 0 1 0 0 2 2 0 0 1 1 0 0 1 0 5 1 0 2 1 2 1 4 0 0 0 0 0 1 0 1 0 0 0 4 3 0 0 0 0 7 3 2 1 3 1 0 1 2 0 6 1 0 0 3 5 2 0 0 0 0 2 1 2 2 0 3 4 2 3 4 0 0 1 0 0 0 2 0 0 0 0 1 2 1 1 0 0 3 2 3 2 1 2 1 2 0 0 0 0 0 0 2 1 0 0 0 7 0 0 1 1 1 0 4 4 2 0 1 0 4 0 0 0 4 3 2 1 0 4 1 2 1 0 0 2 1 2 0 0 1 0 2 0 5 0 1 0 1 4 4 1 3 0 0 1 2 0 0 0 0 1 0 0 0 2 1 4 2 0 0 2 5 0 1 2 0 2 3 4 1 2 1 2 0 0 4 3 1 2 1 1 0 0 0 1 0 1 2 1 0 1 1 0 0 0 0 0 0 1 0 0 0 2 0 0 0 0 1 0 0 0 0 0 0 0 0 0 2 1 0 0 3 0 2 2 1 0 0 1 1 0 0 0 0 1 0 0 0 1 0 2 5 0 2 0 3 1 1 0 1 4 0 1 1 0 0 1 2 0 0 1 0 0 0 1 0 1 1 2 0 2 2 0 0 0 2 0 0 1 2 2 0 2 0 1 0 3 0 0 4 3 1 0 0 0 3 0 1 1 1 1 0 0 0 0 2 0 0 0 0 5 2 1 0 5 0 2 2 1 7 1 1 1 2 1 0 3 0 2 0 0 1 0 0 0 3 0 1 0 1 0 2 1 0 2 6 0 1 0 0 0 1 1 0 3 0 0 1 0 0 0 0 0 0 3 3 2 0 0 4 0 0 0 5 0 0 0 0 3 0 1 1 0 0 0 0 0 0 0 0 0 1 0 2 0 1 0 0 0 0 1 6 0 2 1 0 1 2 0 1 1 0 1 0 0 1 0 2 0 0 0 1 4 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 7 1 0 0 2 0 0 2 0 1 0 4 0 0 2 2 1 0 0 0 1 0 4 0 0)
  )

;? (def random-level()
;?   (ret n 0
;?     (while (and (< 0.5 (rand)) (<= n skip-list-max-level*))
;?       (++ n))))

(def random-level()
  (pop random-level-seed))

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
;?   (each n nd!next (prn n!val)))

(def find-sl(sl v)
  (with (n sl
         l (- skip-list-max-level* 1))
    (while (> l 0)
      (= n (scan n v l))
      (-- l))
    (if (is n skip-list-max-node*) (prn "MAX"))
    (prn n!val)
    (prn n!val " " (len n!next))
    (if (no n!next) (prn "XXX: " n!next))
    (on-err (fn(ex) (prn "XXX " n!next))
            (fn() n!next.0))
;?     (prn-next-pointers n)
    (if (no n!next.0) (prn "nil next"))
    (if (iso n!next.0!val v)
      n!next.0)))

; from nd on level l, prev of smallest node larger than value v
(def scan(nd v l)
  (ret n nd
;?     (prn l)
;?     (prn n!next)
;?     (prn n!next.l!val)
    (while (> v n!next.l!val)
;?       (prn n!val)
      (= n n!next.l))))
