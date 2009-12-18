(= snapshots-dir* "snapshots")

(mac most-recent-snapshot-name(var)
   ;; max works because times lie between 10^9s and 2*10^9s
   `(aif (apply max (keep [iso ,(stringify var)
                   (car:split-by _ ".")]
             (dir snapshots-dir*)))
      (+ snapshots-dir* "/" it)))

(mac load-snapshot(var initval)
  `(aif (most-recent-snapshot-name ,var)
      (unless (bound ',var)
        (init ,var ,initval)
        (fread it ,var))
      (or (init ,var ,initval) ,var)))

(mac new-snapshot-name(var)
  `(+ ,(+ snapshots-dir* "/" (stringify var) ".") ,(seconds)))

(mac save-snapshot(var)
  `(fwritefile (new-snapshot-name ,var) ,var))



;;; Transparent persistence
(= save-registry* ())

; when data changed, run appropriate hook from save-registry*
(after-exec sref(com val ind)
  (aif (alref save-registry* com)
    (buffered-exec it)))

; hook from save-registry lines up save function
(mac setup-autosave(var value)
  `(let ref (load-snapshot ,var ,value)
     (if (no:alref save-registry* ref)
       (push (list ref (fn() (atomic:save-snapshot ,var)))
             save-registry*))))



(mac persisted(var value . body)
  `(do
     (setup-autosave ,var ,value)
     ,@body))

(mac defreg(fnname args registry . body)
  `(do
     (init ,registry ())
     (def ,fnname ,args ,@body)
     (add-to ,registry ,fnname)))



(def fwritefile(filename val)
  (let tmpfile (+ filename ".tmp")
    (fwrite tmpfile val)
    (mvfile tmpfile filename)))

(def fwrite(filename val)
  (w/outfile f filename
    (if (isa val 'table)
      (write-nested-table val f)
      (write val f))))

(mac fread(filename val)
  (let f (uniq)
    `(w/infile ,f ,filename
        (if (isa ,val 'table)
          (= ,val (read-nested-table ,f))
          (= ,val (read ,f))))))



;; Create a thread to pick items up from a fifo and process them.
;; Optionally insert into nextfifo after processing.
;; Create variables to hold the thread and a circular log buffer
(mac defscan(fnname fifo . block)
  (with ((nextfifo body) (extract-car block 'string)
         log-var (symize stringify.fnname "-log*"))
    `(do
       (init ,log-var ())
       (def ,fnname()
         (prn ,stringify.fnname " watching fifos/" ,fifo)
         (forever:each doc (tokens:slurp ,(+ "fifos/" fifo))
            (rotlog ,log-var doc)
            (do1
              (do ,@body)
              ,(aif nextfifo `(w/outfile f ,(+ "fifos/" it) (disp doc f))))))
       (init ,(symize stringify.fnname "-thread*") (new-thread ,fnname)))))



;; memoization with programmable clear
(init cmemo-cache* (table))

(def clear-cmemos(cachename)
  (= cmemo-cache*.cachename nil))

(def cmemo-cache(cachename name)
  (or= cmemo-cache*.cachename (table))
  ;; Beware collisions in name
  (or= cmemo-cache*.cachename.name (list (table) (table)))
  cmemo-cache*.cachename.name)

(def cmemo(f name cachename)
  (fn args
    (let (cache nilcache) (cmemo-cache cachename name)
      (or (cache args)
          (and (no (nilcache args))
               (aif (apply f args)
                    (= (cache args) it)
                    (do (set (nilcache args))
                        nil)))))))

(mac defcmemo (name params cachename . body)
  `(safeset ,name (cmemo (fn ,params ,@body) ',name ,cachename)))

(mac do-cmemo (cachename . body)
  `(do1
     (do ,@body)
     (clear-cmemos ,cachename)))



;;; Stateful constructs with referential transparency and transparent
;;; persistence:
;;; a) mhash - memoize forward lookup
;;; b) rhash - save reverse lookup
;;; c) dhash - two-way lookup
;;;
;;; Policies specify how to handle collisions in the reverse direction.
;;; e.g. indexing is reverse lookup of keyword extraction with policy rcons.

(mac mhash(key-name value-name association body (o merge-policy 'rcons))
  (hash-helper t nil key-name value-name association body merge-policy))
(mac rhash(key-name value-name association body (o merge-policy 'rcons))
  (hash-helper nil t key-name value-name association body merge-policy))
(mac dhash(key-name value-name association body (o merge-policy 'rcons))
  (hash-helper t t key-name value-name association body merge-policy))

(def hash-helper(forward backward key-name value-name association body policy)
  (withs ((pluralize-key pluralize-value) (pluralize-controls association)
          key-str (stringify key-name)
          value-str (stringify value-name)
          check-function-name (symize value-str "?")
          lookup-function-name
                      (pluralized-fnname key-str value-str pluralize-value)
          reverse-lookup-function-name
                      (pluralized-fnname value-str key-str pluralize-key)
          key-table-name (globalize key-str "s")
          value-table-name (globalize value-str "s")
          value-table-nil-name (globalize value-str "-nils")
          create-function-name (symize "create-" key-str "-" value-str)
          set-function-name (symize "set-" key-str "-" value-str))

    `(do
      (setup-autosave ,key-table-name (table))
      (setup-autosave ,value-table-name (table))
      (setup-autosave ,value-table-nil-name (table))
      (def ,create-function-name(,key-name)
        ,body)
      (def ,set-function-name(,key-name)
        (let ,value-name (,create-function-name ,key-name)
          ,(if forward
             `(if ,value-name
                 (= (,value-table-name ,key-name) ,value-name)
                 (= (,value-table-nil-name ,key-table-name) t)))
          ,(if backward
             `(update ,key-table-name ,value-name ,policy ,key-name))
          ,value-name))
      (def ,lookup-function-name(,key-name)
        (and (no (,value-table-nil-name ,key-name))
             (or (,value-table-name ,key-name)
                 (,set-function-name ,key-name))))
      (def ,reverse-lookup-function-name(,value-name)
        (,key-table-name ,value-name))
      (def ,check-function-name(,key-name)
        (,value-table-name ,key-name)))))

(def pluralized-fnname(a b bs)
  (symize a "-"
          (if bs
            (plural-of b)
            b)))

(def pluralize-controls(s)
  (let as (stringify s)
    (list (not (iso (as 0) #\1))
          (not (iso (as 2) #\1)))))

(def update(table key transform value)
  (if (acons key)
    (each k key
      (update table k transform value))
    (= (table key) (transform (table key) value))))

; Policies (storage var -> storage)
(def rcons(l a) (cons a l))
(def or=fn(l a) (or= l a)) ; first lookup wins
(def replace(old new) new) ; last lookup wins
; Policy generator
(def most2(f) (fn(old new) (most-skipping-nils f (list old new))))
