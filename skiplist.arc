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

(def slist((o transformer))
  (obj fn transformer height skip-list-max-height* next nils.skip-list-max-level*))

(def nils(n)
  (accum acc
    (repeat n (acc skip-list-max-node*))))

(def slnode(v)
  (let l (random-level)
    (obj val v height (+ l 1) next (nils (+ l 1)))))

(def val(sl slnode)
  (prn "val " sl!fn " " slnode!val)
  (if (and sl!fn (no:is slnode skip-list-max-node*))
    (sl!fn slnode!val)
    slnode!val))

(def sl-nilnode?(n)
  (iso n skip-list-max-node*))

(mac loop-levels(var node . body)
  `(letloop ,var (- (,node 'height) 1)
                 (>= ,var 0)
                 (-- ,var)
      ,@body))

(proc insert-sl(sl v)
  (let node slnode.v
    (prn "inserting " v " of height " node!height)
    (loop-levels l node
      (fit-level sl node l))))

(proc fit-level(sl node level)
  (prn " fitting level " level)
  (let n (scan sl sl (val sl node) level)
    (prn "n: " n)
    (= node!next.level n!next.level)
    (= n!next.level node)))

(def slen(sl)
  (ret ans 0
    (letloop n sl!next.0
               (no:is n skip-list-max-node*)
               (= n n!next.0)
      (++ ans))))

(proc prn-skip-list(sl)
  (letloop n sl!next.0
             (no:is n skip-list-max-node*)
             (= n n!next.0)
    (pr (val sl n) ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

(proc prn-next-pointers(sl nd)
  (prn:map [val sl _] nd!next))

(def find-sl(sl v)
  (with (n sl
         l (- skip-list-max-level* 1))
    (while (>= l 0)
      (= n (scan sl n v l))
      (-- l))
    (if (iso v (val sl n!next.0))
      n!next.0)))

(def sl-index(sl v)
  (ret ans 0
    (letloop n sl
               (and (no:is v (val sl n)) (no:is n skip-list-max-node*))
               (= n n!next.0)
      (++ ans))))

; from nd on level l, prev of smallest node larger than value v
(def scan(sl nd v l)
  (ret n nd
    (prn "scan")
    (while (> v (val sl n!next.l))
      (prn "iter")
      (= n n!next.l))))
