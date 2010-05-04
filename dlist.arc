; Ported from http://eli.thegreenplace.net/2007/10/03/sicp-section-332
; Exercise 3.23
(mac proc(fnname args . body)
  `(def ,fnname ,args
    ,@body
    nil))

(mac ret(var val . body)
  `(let ,var ,val
     ,@body
     ,var))

(def dlist((o elems))
  (ret ans (annotate 'dlist (list '() '() 0))
    (each elem elems
      (push-back ans elem))))

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

(def dl-empty?(dl)
  (no da.dl))

(def dl-front(dl)
  (val da.dl))

(def dl-back(dl)
  (val db.dl))

(proc push-front(dl v)
  (let n (cons (cons v '()) '())
    (++ dl-len.dl)
    (if (dl-empty? dl)
      (= da.dl n db.dl n)
      (= (prev da.dl)   n
         (next n)       da.dl
         da.dl          n))))

(proc push-back(dl v)
  (let n (cons (cons v '()) '())
    (++ dl-len.dl)
    (if (dl-empty? dl)
      (= da.dl n db.dl n)
      (= (next db.dl)   n
         (prev n)       db.dl
         db.dl          n))))

(def pop-front(dl)
  (unless (dl-empty? dl)
    (-- dl-len.dl)
    (ret ans (val da.dl)
      (if (is da.dl db.dl)
        (= da.dl nil db.dl nil)
        (wipe (prev (next da.dl))))
      (= da.dl (next da.dl)))))

(def pop-back(dl)
  (unless (dl-empty? dl)
    (-- dl-len.dl)
    (ret ans (val db.dl)
      (if (is da.dl db.dl)
        (= da.dl nil db.dl nil)
        (wipe (next (prev db.dl))))
      (= db.dl (prev db.dl)))))

(def dl-elems(dl)
  (accum acc
    (let curr da.dl
      (while curr
        (acc caar.curr)
        (zap cdr:car curr)))))
