(mac randpick args
  (w/uniq (x ans)
    `(with (,x (rand)
            ,ans nil)
      ,@(accum acc
         (each (thresh expr) (pair args)
           (acc `(when (and (no ,ans)
                            (< ,x ,thresh))
                   (= ,ans ,expr))))
         (acc ans)))))

(def shuffle(ls)
  (let n len.ls
    (ret ans copy.ls
      (repeat (/ n 2)
        (swap (ans rand.n) (ans rand.n))))))

(mac findg(generator test)
  (w/uniq (ans count)
    `(ret ,ans ,generator
       (let ,count 0
         (until (or (,test ,ans) (> (++ ,count) 10))
            (= ,ans ,generator))
         (unless (,test ,ans)
           (= ,ans nil))))))

; counterpart of only: keep retrying until expr returns something, then apply f to it
(mac always(f expr)
  `(,f (findg ,expr ,f)))

; random elem in from that isn't already in to (and satisfies f)
(def random-new(from to (o f))
  (ret ans nil
    (let counter 0
      (until (or ans (> (++ counter) 10))
        (let curr randpos.from
          (when (and (~pos curr to)
                     (or no.f
                         (f curr)))
            (= ans curr)))))))

; Make random selection easier.
(def make-rrand(l (o tb (table)) (o rtb (table)) (o origl nil) (o n 0))
  (if (no l)
    (list origl tb rtb n)
    (do
      (= (tb n) (car l))
      (= (rtb car.l) n)
      (make-rrand cdr.l tb rtb (or origl l) (+ n 1)))))

(def rrand-maybe-list(rr) ; may contain deleted elems
  rr.0)
(def rrand-len(rr)
  rr.3)
(def rrand-lookup-table(rr)
  rr.2)
(def rrand-random-table(rr)
  rr.1)

(def rrand(rr)
  (rr.1 (rand rr.3)))

(def add-rrand(rr v)
  (unless (rr.2 v)
    (push v rr.0)
    (= (rr.1 rr.3) v)
    (= (rr.2 v) rr.3)
    (++ rr.3)))

(def check-rrand(rr v)
  (rr.2 v))

(def del-rrand(rr v)
  (when rr
    (whenlet n (rr.2 v)
      ; too expensive to update rr.0
      (wipe rr.1.n)
      (wipe rr.2.v)
      (-- rr.3))))
