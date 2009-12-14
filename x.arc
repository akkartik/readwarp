;; http://arclanguage.org/item?id=10696
(= buffered-execs* (table))

(def buffer-exec (f (o delay 1))
  (unless buffered-execs*.f
    (= buffered-execs*.f 
       (thread (sleep delay) (wipe buffered-execs*.f) (f)))))

(= dbs* ())

(def db (fname (o delay 0.5))  ; file "synced" every 0.5 sec
  (withs (tbl (safe-load-table fname)
        savefn (fn () (atomic:save-table tbl fname)))
    (push (list tbl (fn () (buffer-exec savefn delay))) dbs*)
    tbl))

(let _sref sref
  (def sref (com val ind)
    (prn com)
    (do1 (_sref com val ind)
      (prn com)
      (awhen (and (isa com 'table) (alref dbs* com)) (it)))))
