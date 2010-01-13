(init skiplist-max-height* 28)
(init skiplist-max-level* (- skiplist-max-height* 1))
(init skiplist-max* (expt 2 skiplist-max-height*))
(init skiplist-max-node*
   (obj val skiplist-max* height skiplist-max-level* next nil))

(def slist((o transformer))
  (obj fn transformer height skiplist-max-height* next nils.skiplist-max-height*))

(def slnode(v)
  (let h (+ 1 (random-level))
    (obj val v height h next nils.h)))

(def best-sl(sl (o pred (fn(x) t)))
  (let n sl!next.0
    (until (or (pred n!val)
               (is skiplist-max-node* n))
      (= n n!next.0))
    n!val))

(def metric(sl slnode)
  (if (and sl!fn (~is slnode skiplist-max-node*))
    (or= slnode!metric (sl!fn slnode!val))
    slnode!val))

(def slen(sl)
  (ret ans 0
    (letloop n sl!next.0
               (~is n skiplist-max-node*)
               (= n n!next.0)
      (++ ans))))

(proc prn-sl(sl)
  (letloop n sl!next.0
             (~is n skiplist-max-node*)
             (= n n!next.0)
    (pr n!val " " (metric sl n) ": ")
    (each pointer n!next
      (pr "."))
    (prn)))

(proc prn-slnode(sl nd)
  (pr nd!val ": ")
  (prn:map [metric sl _] nd!next))

(def sl-index(sl v)
  (ret ans 0
    (letloop n sl
               (and (~is v n!val)
                    (~is n skiplist-max-node*))
               (= n n!next.0)
      (++ ans))))



(proc insert-sl(sl v)
  (with (node slnode.v
         n    sl)
    (letloop l (- node!height 1) (>= l 0) (-- l)
      (= n (scan sl n node l))
      (= node!next.l n!next.l)
      (= n!next.l node))))

; On level l, prev of smallest node larger than v
(= skiplist-travs* 0)
(def scan(sl nd v l)
  (ret n nd
    (while (> (metric sl v) (metric sl n!next.l))
      (++ skiplist-travs*)
      (= n n!next.l))))



(def tied(sl a b)
  (unless (or (pos skiplist-max-node* (list a b))
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
         l    (- skiplist-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan-handling-ties sl n nv l))
      (-- l))
    (if (iso v n!next.0!val)
      n!next.0)))

(proc delete-sl(sl v)
  (with (n    sl
         l    (- skiplist-max-level* 1)
         nv   slnode.v)
    (while (>= l 0)
      (= n (scan-handling-ties sl n nv l))
      (if (iso v n!next.l!val)
        (= n!next.l n!next.l!next.l))
      (-- l))))



(def random-level()
  (ret n 0
    (while (and (< 0.5 (rand)) (<= n skiplist-max-level*))
      (++ n))))

(def nils(n)
  (accum acc
    (repeat n (acc skiplist-max-node*))))

(def sl-trans(sl)
  (or sl!fn id))

(def sl-nilnode?(n)
  (iso n skiplist-max-node*))
