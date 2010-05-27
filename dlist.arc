; Ported from http://eli.thegreenplace.net/2007/10/03/sicp-section-332
; Exercise 3.23
(def dlist((o elems))
  (if (isa elems 'dlist)
    elems
    (ret ans (annotate 'dlist (list '() '() 0))
      (each elem elems
        (push-back ans elem)))))

(def dlist?(l)
  (or (isa l 'dlist)
      (and (isa l 'cons)
           (is car.l 'dlist))))

(mac da(dl)
  `((rep ,dl) 0))

(mac db(dl)
  `((rep ,dl) 1))

(mac dl-len(dl)
  `((rep ,dl) 2))

(mac prev(node)
  `(cdr ,node))

(mac next(node)
  `(cdr:car ,node))

(mac val(node)
  `(car:car ,node))

(def dl-elems(dl)
  (if dl
    (accum acc
      (let curr da.dl
        (while curr
          (acc val.curr)
          (= curr next.curr))))))

(defmethod serialize(agg) dlist
  (list 'dlist (map serialize dl-elems.agg)))
(pickle dlist serialize)

(defmethod unserialize(l) dlist
  (dlist (map unserialize cadr.l)))

(def dl-empty?(dl)
  (no da.dl))

(def dl-front(dl)
  (val da.dl))

(def dl-back(dl)
  (val db.dl))

(proc push-front(dl v)
  (let n (cons (cons v '()) '())
    (atomic
      (++ dl-len.dl)
      (if (dl-empty? dl)
        (= da.dl n db.dl n)
        (= (prev da.dl)   n
           (next n)       da.dl
           da.dl          n)))))

(proc push-back(dl v)
  (let n (cons (cons v '()) '())
    (atomic
      (++ dl-len.dl)
      (if (dl-empty? dl)
        (= da.dl n db.dl n)
        (= (next db.dl)   n
           (prev n)       db.dl
           db.dl          n)))))

(def pop-front(dl)
  (atomic
    (unless (dl-empty? dl)
      (-- dl-len.dl)
      (ret ans (val da.dl)
        (if (is da.dl db.dl)
          (= da.dl nil db.dl nil)
          (wipe (prev (next da.dl))))
        (= da.dl (next da.dl))))))

(def pop-back(dl)
  (atomic
    (unless (dl-empty? dl)
      (-- dl-len.dl)
      (ret ans (val db.dl)
        (if (is da.dl db.dl)
          (= da.dl nil db.dl nil)
          (wipe (next (prev db.dl))))
        (= db.dl (prev db.dl))))))

(def pushn(dl v n)
  (push-front dl v)
  (when (> dl-len.dl n)
    (pop-back dl)))
