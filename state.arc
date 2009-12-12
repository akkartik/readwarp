;;; Transparent persistence
(= load-registry* () save-registry* () scan-registry* ())

(def load-state()
  (prn "*** Loading state")
  (each loadfn load-registry*
    (loadfn)))

(def save-state()
  (each savefn save-registry*
    (savefn)))

(def scan-state()
  (prn "*** Scanning for new data")
  (each scanfn scan-registry*
    (scanfn)))



(mac is-persisted(var)
  (withs (save-function-name (symize "save-" var)
          load-function-name (symize "load-" var))
    `(do
      (def ,save-function-name()
        (fwritefile (snapshot-name ,var) ,var))
      (def ,load-function-name()
        (when (file-exists (snapshot-name ,var))
          (prn "Loading " ',var)
          (fread (snapshot-name ,var) ,var)))
      (add-to load-registry* ,load-function-name)
      (add-to save-registry* ,save-function-name))))

(mac persisted(var value . body)
  `(do
     (init ,var ,value)
     (is-persisted ,var)
     ,@body))



(mac defreg(fnname args registry . body)
  `(do
     (init ,registry ())
     (def ,fnname ,args ,@body)
     (add-to ,registry ,fnname)))

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
              ,(aif nextfifo `(fwrite ,(+ "fifos/" it) doc)))))
       (init ,(symize stringify.fnname "-thread*") (new-thread ,fnname)))))



(mac snapshot-name(var)
  `(+ "snapshot." ,(stringify var)))

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



;; memoization with programmable clear
(init cmemo-cache* (table))

(def clear-cmemos(cachename)
  (= cmemo-cache*.cachename nil))

(def cmemo-cache(cachename name)
  (or= cmemo-cache*.cachename (table))
  (or= cmemo-cache*.cachename.name (list (table) (table))) ;; Beware collisions in name
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



;;; Stateful constructs with referential transparency and transparent persistence:
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
          lookup-function-name (symize key-str "-" (if pluralize-value
                                                     (plural-of value-str)
                                                     value-str))
          reverse-lookup-function-name (symize value-str "-" (if pluralize-key
                                                               (plural-of key-str)
                                                               key-str))
          key-table-name (globalize key-str "s")
          value-table-name (globalize value-str "s")
          create-function-name (symize "create-" key-str "-" value-str)
          set-function-name (symize "set-" key-str "-" value-str)
          save-function-name (symize "save-" key-str "-" value-str "-tables")
          load-function-name (symize "load-" key-str "-" value-str "-tables")
          arg (uniq)
          fport (uniq)
          snapshot-file-name (+ key-str "-" value-str "s"))

    `(with (,key-table-name (table)
            ,value-table-name (table))
        (def ,(symize key-str "s-table")() ,key-table-name) (def ,(symize value-str "s-table")() ,value-table-name)
        (def ,create-function-name(,key-name)
          ,body)
        (def ,set-function-name(,key-name)
          (let ,value-name (,create-function-name ,key-name)
            ,(if forward
               `(= (,value-table-name ,key-name) ,value-name))
            ,(if backward
               `(update ,key-table-name ,value-name ,policy ,key-name))
            ,value-name))
        (def ,lookup-function-name(,key-name)
          (or (,value-table-name ,key-name)
              (,set-function-name ,key-name)))
        (def ,reverse-lookup-function-name(,value-name)
          (,key-table-name ,value-name))
        (def ,check-function-name(,key-name)
          (,value-table-name ,key-name))

        (def ,save-function-name()
          (w/outfile ,fport (snapshot-name ,snapshot-file-name)
            (write-table ,key-table-name ,fport)
            (disp #\newline ,fport)
            (write-table ,value-table-name ,fport)))
        (def ,load-function-name()
          (when (file-exists (snapshot-name ,snapshot-file-name))
            (prn "Loading " (snapshot-name ,snapshot-file-name))
            (w/infile ,fport (snapshot-name ,snapshot-file-name)
              (= ,key-table-name (read-table ,fport))
              (= ,value-table-name (read-table ,fport)))))
        (add-to load-registry* ,load-function-name)
        (add-to save-registry* ,save-function-name))))

(def pluralize-controls(s)
  (let as (stringify s)
    (list (not (iso (as 0) #\1)) (not (iso (as 2) #\1)))))

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
