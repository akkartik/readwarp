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
(def make-rrand(l (o tb (table)) (o rtb (table)) (o n 0))
  (if (no l)
    (list tb rtb n)
    (do
      (= (tb n) (car l))
      (= (rtb car.l) n)
      (make-rrand cdr.l tb rtb (+ n 1)))))
(def rrand(rr)
  (rr.0 (rand rr.2)))
(def add-rrand(rr v)
  (unless (rr.0 rr.2)
    (= (rr.0 rr.2) v)
    (= (rr.1 v) rr.2)
    (++ rr.2)))
(def del-rrand(rr v)
  (when rr
    (let n (rr.1 v)
      (wipe rr.1.v)
      (wipe rr.0.n))))
