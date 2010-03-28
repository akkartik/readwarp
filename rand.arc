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

; counterpart to only: keep retrying until expr returns something that passes
; f, then apply f to it
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



; State machine for exponential backoff.
; Each elem contains a 3-tuple: an item, a backoff limit, and a list of attempts.
(def backoff(item n)
  (list item n nil))

(def backoff-item(b)
  b.0)
(def backoff-limit(b)
  b.1)
(def backoff-attempts(b)
  b.2)

(def backoff-add(b attempt)
  (push attempt b.2))

(def backoff-borderline(b)
  (when b
    (>= (len b.2) (- b.1 1))))

(mac backoff-check(b pred)
  `(when (>= (len (,b 2)) (,b 1))
    (if ,pred
      (wipe ,b)
      (backoff-again ,b))))

(mac backoff-again(b)
  `(zap [* 2 _] (,b 1)))

(def backoff-clear(b)
  (when b
    (wipe b.2)))

; backoff structures are often organized in tables
(def backoffify(l n)
  (w/table ans
    (each elem l
      (= ans.elem (backoff elem n)))))



(= default-rrand-backoff* 2)

; Make random selection easier.
(def make-rrand((o l) (o tb (table)) (o rtb (table)) (o origl) (o n 0))
  (if (no l)
    (list origl tb rtb n)
    (do
      (= (tb n) (car l))
      (= (rtb car.l) (backoff n default-rrand-backoff*))
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
  (when (and rr (> rr.3 0))
    (rr.1 (rand rr.3))))

(def add-rrand(rr v)
  (unless (rr.2 v)
    (push v rr.0)
    (= (rr.1 rr.3) v)
    (= (rr.2 v) (backoff rr.3 default-rrand-backoff*))
    (++ rr.3)))

(def check-rrand(rr v)
  (only.backoff-item rr.2.v))

(def empty-rrand(rr)
  (empty rrand-lookup-table.rr))

(def del-rrand(rr v)
  (whenlet nb (rr.2 v)
    ; too expensive to update rr.0
    (wipe (rr.1 nb.0))
    (wipe rr.2.v)
    (-- rr.3)))

(def backoff-rrand(rr v x delete)
  (when (and rr rr.2.v)
    (let n rr.2.v.0
      (backoff-add rr.2.v x)
      (backoff-check rr.2.v delete)
      (unless rr.2.v
        (wipe rr.1.n)
        (-- rr.3)))))

(def backoff-clear-rrand(rr v)
  (when rr
    (backoff-clear rr.2.v)))

(def backoff-borderline-rrand(rr v)
  (when rr
    (backoff-borderline rr.2.v)))
