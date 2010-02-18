(= snapshots-dir* "snapshots")

(mac most-recent-snapshot-name(var)
   ; max works because times lie between 10^9s and 2*10^9s
   `(aif (apply max
          (keep
              [and (iso ,(stringify var) (car:split-by _ "."))
                   (~posmatch ".tmp" _)]
             (dir snapshots-dir*)))
      (+ snapshots-dir* "/" it)))

(mac load-snapshot(var initval)
  `(aif (most-recent-snapshot-name ,var)
      (when (or (~bound ',var) (no ,var))
        (init ,var ,initval)
        (prn "Loading " ',var)
        (fread it ,var)
        (unless (is (type ,var) (type ,initval))
          (prn "Error: corrupted snapshot " it)
          (quit)))
      (or (init ,var ,initval) ,var)))

(mac new-snapshot-name(var (o timestamp))
  `(+ (+ snapshots-dir* "/" ,(stringify var) ".")
      (or ,timestamp
          ,(seconds)))) ; one file per session. remove comma to stop reusing

(mac save-snapshot(var (o timestamp))
  `(fwritefile (new-snapshot-name ,var ,timestamp) ,var))



;;; Transparent persistence
(init autosaved-vars* ())
(mac setup-autosave(var value)
  `(do
     (load-snapshot ,var ,value)
     (pushnew ',var autosaved-vars*)))

(mac persisted(var value . body)
  `(do
     (setup-autosave ,var ,value)
     ,@body))

(mac without-updating-state body
  `(after*
     (set disable-autosave*)
     ,@body
    :do
     (wipe disable-autosave*)))



(mac defreg(fnname args registry . body)
  `(do
     (init ,registry ())
     (proc ,fnname ,args ,@body)
     (add-to ,registry ,fnname)))

(mac defrep(fnname interval . body)
  `(do
     (init ,(symize stringify.fnname "-init*") nil)
     (proc ,fnname()
        ; Make the first iter go as fast as possible in case we're waiting at
        ; file load time.
       (atomic ,@body)
       (set ,(symize stringify.fnname "-init*"))
       (sleep ,interval)
       (forever
         ,@body
         (set ,(symize stringify.fnname "-init*"))
         (sleep ,interval)))
     (init ,(symize stringify.fnname "-thread*") (new-thread ,stringify.fnname ,fnname))))

(= really-quit quit)

(init disable-autosave* t)
(init prn-autosave* nil)
(init quit-after-autosave* nil)
(defrep save-state 300
  (let session-timestamp (seconds)
    (unless disable-autosave*
      (if prn-autosave* (prn "Saving"))
      (each var autosaved-vars*
        (if prn-autosave* (prn " " var))
        (eval `(save-snapshot ,var ,session-timestamp))
        (sleep 10))
      (if quit-after-autosave* (really-quit)))))

(def quit()
  (prn "Killing scans")
  (each thd scan-registry*
    (kill-thread thd))
  (prn "Waiting for autosave to complete")
  (set prn-autosave* quit-after-autosave*))



(def fwritefile(filename val)
  (let tmpfile (+ filename ".tmp")
    (fwrite tmpfile val)
    (until file-exists.tmpfile)
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
(init scan-registry* nil)
(mac defscan(fnname fifo . block)
  (with ((nextfifo body) (extract-car block 'string)
         log-var (symize stringify.fnname "-log*")
         thread-var (symize stringify.fnname "-thread*"))
    `(do
       (init ,log-var ())
       (proc ,fnname()
         (prn ,stringify.fnname " watching fifos/" ,fifo)
         (forever:each doc (tokens:slurp ,(+ "fifos/" fifo))
            (rotlog ,log-var doc)
            ,@body
            ,(aif nextfifo `(w/outfile f ,(+ "fifos/" it) (disp doc f)))))
       (init ,thread-var (new-thread ,stringify.fnname ,fnname))
       (pushnew ,thread-var scan-registry*))))



(def chunk-files(var)
  (tokens:tostring:system (+ "ls -t snapshots/" stringify.var "-chunk* |grep -v 'tmp$'")))

(mac load-chunks(var)
  (let ans (uniq)
  `(init ,var
          (w/table ,ans
            (prn "loading " ',var)
            (each file (firstn 50 (chunk-files ',var))
              (prn "  " file)
              (w/infile f file
                (each (k v) (read-nested-table f)
                  (= (,ans k) v))))))))

(mac save-to-chunk(var val ind)
  `(do
    (push (list ,ind ,val) ,(globalize stringify.var "-chunk"))
    (test-save ,(globalize stringify.var "-chunk"))))

(init chunk-counter* 0)
(init chunk-size* 1000)
(mac test-save(var)
  `(when (>= (len ,var) chunk-size*)
     (atomic
       (zap rev ,var)
       (save-chunked-snapshot ,var chunk-counter*)
       (++ chunk-counter*)
       (wipe ,var))))

(mac save-chunked-snapshot(var i)
  `(fwritefile (+ (new-snapshot-name ,var) "." ,i) ,var))

(init chunked-persisted-vars* nil)
(mac chunked-persisted(var)
  `(do
     (init ,(globalize stringify.var "-chunk") nil)
     (let ref (load-chunks ,var)
       (push (list ref ',var) chunked-persisted-vars*))))

(extend sref(com val ind) (alref chunked-persisted-vars* com)
  (eval `(save-to-chunk ,(alref chunked-persisted-vars* com) ',(tablist2 val) ,ind))
  (orig com val ind))

(mac explode-persisted-list(var filename . body)
  (w/uniq f
    `(w/infile ,f ,filename
      (while (aand (readc ,f)
                   (~is it #\()))
      (on-err (fn(ex)
                (let msg details.ex
                  (unless (posmatch "read: unexpected `)'" msg)
                    (prn msg))))
        (fn()
          (let i 0
            (whilet ,var (read ,f)
              (++ i)
              (if (is 0 (remainder i chunk-size*))
                (prn i))
              ,@body)))))))

(mac chunk-snapshot(filename var)
  (w/uniq x
    `(let ,var nil
      (explode-persisted-list ,x ,filename
        (push ,x ,var)
        (test-save ,var)))))

(def skiplistify(n)
  (/ n 10))

(def alist-timestamp(x)
  (let n x.1
    (skiplistify:or
      (alref n 'date)
      (alref n 'feeddate)
      0)))

(mac chunk-bounded-snapshot(filename var n)
  (w/uniq x
    `(let ,var nil
      (explode-persisted-list ,x ,filename
        (push ,x ,var))
      (prn "sorting")
      (sort-by alist-timestamp ,var)
      (prn "clamping")
      (= ,var (firstn ,n ,var))
      (prn "writing to disk")
      (fwritefile "x" ,var))))



;; memoization with programmable clear
(init cmemo-cache* (table))

(def clear-cmemos(cachename)
  (= cmemo-cache*.cachename nil))

(def cmemo-cache(cachename name)
  ; Beware collisions in name
  (inittab cmemo-cache*.cachename
           name (list (table) (table)))
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
  (hash-helper t nil t key-name value-name association body merge-policy))
(mac rhash(key-name value-name association body (o merge-policy 'replace)) ; doesn't memoize
  (hash-helper nil t t key-name value-name association body merge-policy))
(mac dhash(key-name value-name association body (o merge-policy 'rcons))
  (hash-helper t t t key-name value-name association body merge-policy))
(mac dhash-nosave(key-name value-name association body (o merge-policy 'rcons))
  (hash-helper t t nil key-name value-name association body merge-policy))

(def hash-helper(forward backward save key-name value-name association body policy)
  (withs ((pluralize-key pluralize-value) (pluralize-controls association)
          key-str (stringify key-name)
          value-str (stringify value-name)
          check-function-name (symize key-str "-" value-str "?")
          lookup-function-name
                      (pluralized-fnname key-str value-str pluralize-value)
          reverse-lookup-function-name
                      (pluralized-fnname value-str key-str pluralize-key)
          key-table-name (globalize value-str "-" key-str "s")
          value-table-name (globalize key-str "-" value-str "s")
          value-table-nil-name (globalize key-str "-" value-str "-nils")
          create-function-name (symize "create-" key-str "-" value-str)
          set-function-name (symize "set-" key-str "-" value-str))

    `(do
      ,(if (and save backward)
        `(setup-autosave ,key-table-name (table))
        `(init ,key-table-name (table)))
      ,(if (and save forward)
        `(setup-autosave ,value-table-name (table))
        `(init ,value-table-name (table)))
      ,(if (and save forward)
        `(setup-autosave ,value-table-nil-name (table))
        `(init ,value-table-nil-name (table)))
      (def ,create-function-name(,key-name)
        ,body)
      (def ,set-function-name(,key-name)
        (let ,value-name (,create-function-name ,key-name)
          ,(if forward
             `(if ,value-name
                 (= (,value-table-name ,key-name) ,value-name)
                 (= (,value-table-nil-name ,key-name) t)))
          ,(when backward
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
(def rconsuniq(l a) (if (pos a l) l (cons a l)))
(def or=fn(l a) (or= l a)) ; first lookup wins
(def replace(old new) new) ; last lookup wins
; Policy generator
(def most2(f) (fn(old new) (most-skipping-nils f (list old new))))
