(const snapshots-dir* "snapshots")

(init really-quit quit)

(mac newest-snapshot-name(var)
   ; max works because times lie between 10^9s and 2*10^9s
   `(aif (apply max
          (keep
              [and (iso ,(string var) (car:split-by _ "."))
                   (~posmatch ".tmp" _)]
             (dir snapshots-dir*)))
      (+ snapshots-dir* "/" it)))

(mac load-snapshot(var initval)
  `(aif (newest-snapshot-name ,var)
      (when (or (~bound ',var) (no ,var))
        (init ,var ,initval)
        (prn "Loading " ',var)
        (fread it ,var)
        (unless (is (type ,var) (type ,initval))
          (prn "Error: corrupted snapshot " it)
          (really-quit)))
      (or (init ,var ,initval) ,var)))

(let session-snapshot-idx (remainder (seconds) 10)
  (mac new-snapshot-name(var)
    `(+ snapshots-dir* "/"
        ,string.var
        ".140000000" ; Arbitrary constant, convenient at dev time.
        ,session-snapshot-idx)))

(mac save-snapshot(var)
  `(fwritefile (new-snapshot-name ,var) ,var))



;;; Transparent persistence
(init persisted-vars* ())
(mac persisted(var value)
  `(do
     (load-snapshot ,var ,value)
     (pushnew ',var persisted-vars*)))

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
     (pushnew ',fnname ,registry)))

(mac defrep(fnname interval . body)
  `(do
     (init ,(symize string.fnname "-init*") nil)
     (proc ,fnname()
       (forever
         (log-time ,fnname
           ,@body)
         (sleep ,interval)))
     (init ,(symize string.fnname "-thread*") (new-thread ,string.fnname ,fnname))))

(init disable-autosave* t)
(init prn-autosave* nil)
(init quit-after-autosave* nil)
(let session-timestamp (seconds)
  (defrep autosave-state 300
    (unless disable-autosave*
      (when prn-autosave* (prn "Saving"))
      (each var persisted-vars*
        (when prn-autosave* (prn " " var))
        (eval `(save-snapshot ,var ,session-timestamp))
        (sleep 10))
      (when quit-after-autosave* (really-quit)))))

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
    (write serialize.val f)))

(mac fread(filename val)
  (let f (uniq)
    `(w/infile ,f ,filename
        (= ,val (unserialize:read ,f)))))



;; Create a thread to pick items up from a fifo and process them.
;; Optionally insert into nextfifo after processing.
;; Create variables to hold the thread and a circular log buffer
(init scan-registry* nil)
(mac defscan(fnname fifo . block)
  (with ((nextfifo body) (extract-car block 'string)
         log-var (symize string.fnname "-log*")
         thread-var (symize string.fnname "-thread*"))
    `(do
       (init ,log-var ())
       (proc ,fnname()
         (prn ,string.fnname " watching fifos/" ,fifo)
         (forever:each doc (tokens:slurp ,(+ "fifos/" fifo))
            (rotlog ,log-var doc)
            ,@body
            ,(aif nextfifo `(w/outfile f ,(+ "fifos/" it) (disp doc f)))))
       (init ,thread-var (new-thread ,string.fnname ,fnname))
       (pushnew ,thread-var scan-registry*))))



(def chunk-files(var)
  (tokens:tostring:system (+ "ls -t snapshots/" string.var "-chunk* |grep -v 'tmp$'")))

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
    (push (list ,ind ,val) ,(globalize string.var "-chunk"))
    (test-save ,(globalize string.var "-chunk"))))

(const chunk-counter* 0)
(const chunk-size* 1000)
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
     (init ,(globalize string.var "-chunk") nil)
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
              (when (is 0 (remainder i chunk-size*))
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



; State machine for exponential backoff.
; Each elem contains a 3-tuple: an item, a backoff limit, and a list of attempts.
(def backoff(item n)
  (list item n nil))

(mac backoff-add-and-check(b attempt pred)
  `(when ,b
     (backoff-add ,b ,attempt)
     (backoff-check ,b ,pred)))

(def backoff-add(b attempt)
  (push attempt b.2))

(def backoff-borderline(b)
  (if (is b t)
    (do1 nil (erp "ERRORERRORERROR backoff is t"))
    (when b
      (>= (len b.2) (- b.1 1)))))

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



(mac lookup-or-generate-transient(place expr ? timeout 500)
  `(aif (lookup-transient ,place)
        it
        (do
          (= ,place (transient-value ,expr ,timeout))
          (lookup-transient ,place))))

(def transient-value(v ? timeout 500)
  (let t0 (seconds)
    (annotate 'transient-value (list v t0 (+ t0 timeout)))))

(def lookup-transient(tr)
  (when (isa tr 'transient-value)
    (let (val init timeout) rep.tr
      (when (< (seconds) timeout)
        val))))

(def transval(tr)
  (when (isa tr 'transient-value)
    rep.tr.0))

(def expire-transient(tr)
  (when (isa tr 'transient-value)
    (= rep.tr.2 (- (seconds) 1))))

(defmethod serialize(agg) transient-value
  (list 'transient-value rep.agg))
(defmethod unserialize(l) transient-value
  (annotate 'transient-value cadr.l))



(proc migrate-state()
  (system "touch migrate")
  (quit))
(proc do-any-migrations()
  (when (file-exists "migrate")
    (run-migrations)
    (system "rm migrate")))

(init migrations* nil)
(def run-migrations()
  (prn "running " len.migrations* " migrations")
  (each f migrations*
    (prn " -- migration: " f)
    (eval.f)))



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

(mac mhash(key-name value-name association body ? merge-policy 'rcons)
  (hash-helper t nil t key-name value-name association body merge-policy))
(mac rhash(key-name value-name association body ? merge-policy 'replace) ; doesn't memoize
  (hash-helper nil t t key-name value-name association body merge-policy))
(mac dhash(key-name value-name association body ? merge-policy 'rcons)
  (hash-helper t t t key-name value-name association body merge-policy))
(mac dhash-nosave(key-name value-name association body ? merge-policy 'rcons)
  (hash-helper t t nil key-name value-name association body merge-policy))

(def hash-helper(forward backward save key-name value-name association body policy)
  (withs ((pluralize-key pluralize-value) (pluralize-controls association)
          key-str (string key-name)
          value-str (string value-name)
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
        `(persisted ,key-table-name (table))
        `(init ,key-table-name (table)))
      ,(if (and save forward)
        `(persisted ,value-table-name (table))
        `(init ,value-table-name (table)))
      ,(if (and save forward)
        `(persisted ,value-table-nil-name (table))
        `(init ,value-table-nil-name (table)))
      (def ,create-function-name(,key-name)
        ,body)
      (def ,set-function-name(,key-name)
        (let ,value-name (,create-function-name ,key-name)
          ,(when forward
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
  (let as (string s)
    (list (~iso as.0 #\1)
          (~iso as.2 #\1))))

(def update(table key transform value)
  (if (acons key)
    (each k key
      (update table k transform value))
    (= (table key) (transform (table key) value))))

; Policies (storage var -> storage)
(def rcons(l a) (if (pos a l) l (cons a l))) ; prepend if new
(def or=fn(l a) (or= l a)) ; first lookup wins
(def replace(old new) new) ; last lookup wins

; Policy generators
(def most2(f) (fn(old new) (most-skipping-nils f (list old new))))

(def rconsn(n)
  (fn(old new)
    (firstn n (if (pos new old) old (cons new old)))))

(def fixedq(n on-delete)
  (fn(q val)
    (ret ans (or q (dlist))
      (only.on-delete (pushn ans val n)))))

(def fixq(n on-delete)
  (fn(q val)
    (ret ans (or q (queue))
      (only.on-delete (pushn ans val n)))))
