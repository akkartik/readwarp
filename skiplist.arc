(init skip-list-max-height* 28)
(init skip-list-max-level* (- skip-list-max-height* 1))
(init skip-list-max* (expt 2 skip-list-max-height*))
(init skip-list-max-node*
   (obj val skip-list-max* height skip-list-max-level* next nil))

(def slist((o transformer))
  (obj fn transformer height skip-list-max-height* next nils.skip-list-max-height*))

(def slnode(v)
  (let h (+ 1 (random-level))
    (obj val v height h next nils.h)))

(def best-sl(sl (o pred (fn(x) t)))
  (let n sl!next.0
    (until (or (pred n!val)
               (is skip-list-max-node* n))
      (= n n!next.0))
    n!val))

(def metric(sl slnode)
  (if (and sl!fn (~is slnode skip-list-max-node*))
    (sl!fn slnode!val)
    slnode!val))

(def slen(sl)
  (ret ans 0
    (letloop n sl!next.0
               (~is n skip-list-max-node*)
               (= n n!next.0)
      (++ ans))))

(proc prn-skip-list(sl)
  (letloop n sl!next.0
             (~is n skip-list-max-node*)
             (= n n!next.0)
    (pr n!val " " (metric sl n) ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

(proc prn-next-pointers(sl nd)
  (prn:map [metric sl _] nd!next))

(def sl-index(sl v)
  (ret ans 0
    (letloop n sl
               (and (~is v n!val)
                    (~is n skip-list-max-node*))
               (= n n!next.0)
      (++ ans))))



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

; On level l, prev of smallest node larger than v
(def scan(sl nd v l)
  (ret n nd
    (while (> (metric sl v) (metric sl n!next.l))
      (= n n!next.l))))



(def tied(sl a b)
  (unless (or (pos skip-list-max-node* (list a b))
              (pos sl (list a b)))
    (is (metric sl a) (metric sl b))))

(def valmatch(a b)
  (iso a!val b!val))

(def scan-handling-ties(sl nd v l)
  (blet n (scan sl nd v l) (valmatch v n!next.l)
    (while(and n!next.l!next
               (~valmatch v n!next.l)
               (tied sl n!next.l n!next.l!next.l))
      (= n n!next.l))))

(def find-sl(sl v)
  (with (n    sl
         l    (- skip-list-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan-handling-ties sl n nv l))
      (-- l))
    (if (iso v n!next.0!val)
      n!next.0)))

(proc delete-sl(sl v)
  (with (n    sl
         l    (- skip-list-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan-handling-ties sl n nv l))
      (if (iso v n!next.l!val)
        (= n!next.l n!next.l!next.l))
      (-- l))))



(def random-level()
  (ret n 0
    (while (and (< 0.5 (rand)) (<= n skip-list-max-level*))
      (++ n))))

(def nils(n)
  (accum acc
    (repeat n (acc skip-list-max-node*))))

(def sl-trans(sl)
  (or sl!fn id))

(def sl-nilnode?(n)
  (iso n skip-list-max-node*))
