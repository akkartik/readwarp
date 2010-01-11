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
  (obj fn transformer height skip-list-max-height* next nils.skip-list-max-height*))

(def nils(n)
  (accum acc
    (repeat n (acc skip-list-max-node*))))

(def slnode(v)
  (let h (+ 1 (random-level))
    (obj val v height h next nils.h)))

(def metric(sl slnode)
  (if (and sl!fn (no:is slnode skip-list-max-node*))
    (sl!fn slnode!val)
    slnode!val))

(def sl-trans(sl)
  (or sl!fn id))

(def sl-nilnode?(n)
  (iso n skip-list-max-node*))

(mac loop-levels(var node . body)
  `(letloop ,var (- (,node 'height) 1)
                 (>= ,var 0)
                 (-- ,var)
      ,@body))

(proc insert-sl(sl v)
  (let node slnode.v
;?     (prn "inserting " v " of height " node!height)
    (loop-levels l node
      (fit-level sl node l))))

(proc fit-level(sl node level)
;?   (prn " fitting level " level)
  (let n (scan sl sl node level)
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
    (pr n!val " " (metric sl n) ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

(proc prn-next-pointers(sl nd)
  (prn:map [metric sl _] nd!next))

; from nd on level l, prev of smallest node larger than value of node v
(def scan(sl nd v l)
  (ret n nd
    (while (> (metric sl v) (metric sl n!next.l))
      (= n n!next.l))))

(def sl-index(sl v)
  (ret ans 0
    (letloop n sl
               (and (no:is v (metric sl n)) (no:is n skip-list-max-node*))
               (= n n!next.0)
      (++ ans))))



;? (def scan-handling-ties(sl nd v l)
;?   (ret n (scan sl nd v l)
;?     (if (iso (


(def find-sl(sl v)
  (with (n    sl
         l    (- skip-list-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan sl n nv l))
      (-- l))
    (if (iso v n!next.0!val)
      n!next.0)))

(proc delete-sl(sl v)
  (with (n    sl
         l    (- skip-list-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan sl n nv l))
      (if (iso v n!next.l!val)
        (= n!next.l n!next.l!next.l))
      (-- l))))

(def touch(file)
  (w/outfile f file))

; from nd on level l, prev of smallest node larger than value of node v
(def scan2(sl nd v l)
  (prn "scan2 " l)
;?   prn-skip-list.sl
  (ret n nd
    (prn "aaa " skip-list-max-node* l)
    (prn-next-pointers sl n)
;?     (prn (metric sl n!next.l))
    (prn "bbb")
    (while (> (metric sl v) (metric sl n!next.l))
      (prn n!val)
      (= n n!next.l))
    (prn "ccc " n!val)
    (while (and (no n!val)
                (not:is n skip-list-max-node*)
                (not:is n!next.l skip-list-max-node*)
                (is (metric sl n!next.l) (metric sl n!next.l!next.0))
                (not:iso v!val n!next.l!val))
      (prn " " n!val)
      (= n n!next.0))))
