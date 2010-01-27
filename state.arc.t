(shadowing autosaved-vars* ()
(shadowing snapshots-dir* "test-snapshots"
(system:+ "mkdir -p " snapshots-dir*)
(system:+ "rm " snapshots-dir* "/?s*.*")

(let quit-called nil
  (shadowing quit (fn() set.quit-called)
    (let load-test-snapshot-var1 nil (save-snapshot load-test-snapshot-var1))
    ; polluting namespace; wish I could unbind vars
    (load-snapshot load-test-snapshot-var1 (table))
    (test-iso "nil file loads into empty table"
      (table)
      load-test-snapshot-var1)

    (let load-test-snapshot-var2 "abc" (save-snapshot load-test-snapshot-var2))
    (load-snapshot load-test-snapshot-var2 (table))
    (test-ok "load-snapshot bails on corrupted snapshot file"
             quit-called)))

(test-smatch "setup-autosave works"
  '(let ref (load-snapshot a (table))
    (pushnew 'a autosaved-vars*)
    (if (~alref save-registry* ref)
      (push (list ref (fn nil (save-snapshot a))) save-registry*)))

  (macex1 '(setup-autosave a (table))))



(let f 2
  (fwrite "zzabc" 3)
  (fread "zzabc" f)
  (test-iso "fwrite should write primitive" 3 f))

(let f ()
  (fwrite "zzabc" '(1 3 2))
  (fread "zzabc" f)
  (test-iso "fwrite should write list" '(1 3 2) f))

(let f (table)
  (fwrite "zzabc" (obj a 1 b 2))
  (fread "zzabc" f)
  (test-iso "fwrite should write table" (obj a 1 b 2) f)
  (= (f 'c) 34)
  (test-iso "fread should read mutable table from file" (obj a 1 b 2 c 34) f))
(system "rm zzabc")



(test-iso "defscan adds code to function to read fifo"
  '(do
    (init foo-log* ())
    (proc foo()
      (prn "foo" " watching fifos/" "foo")
      (forever:each doc (tokens:slurp "fifos/foo")
        (rotlog foo-log* doc)
        0
        nil))
    (init foo-thread* (new-thread "foo" foo)))
  (macex1:quote:defscan foo "foo" 0))

(test-iso "defscan optionally adds code to function to write next fifo"
  '(do
    (init foo-log* ())
    (proc foo()
      (prn "foo" " watching fifos/" "foo")
      (forever:each doc (tokens:slurp "fifos/foo")
        (rotlog foo-log* doc)
        0
        (w/outfile f "fifos/foo2" (disp doc f))))
    (init foo-thread* (new-thread "foo" foo)))
  (macex1:quote:defscan foo "foo" "foo2" 0))



(clear-cmemos 'A)

(test-is "clear-cmemos clears the cache"
  t
  (no cmemo-cache*!A))

(= calls-to-test1 0)
(defcmemo test1(a b)
          'A
  (++ calls-to-test1)
  (+ a b))

(= old (test1 3 4))

(test-is "first call saves to cmemo-cache*"
  1
  calls-to-test1)

(test-is "subsequent calls return identical results"
  old
  (test1 3 4))

(test-is "subsequent calls read cmemo-cache*"
  1
  calls-to-test1)

(clear-cmemos 'A)
(test1 3 4)

(test-is "call after clear saves to cmemo-cache* again"
  2
  calls-to-test1)

(defcmemo add-foo(a b) 'test-add
  (+ a b))

(test-iso "do-cmemo returns its body"
  2
  (do-cmemo 'test-add
    (add-foo 1 1)))

(do
  (do-cmemo 'test-add
    (add-foo 1 1))
  (test-iso "do-cmemo clears appropriate cmemo-cache when done"
    nil
    cmemo-cache*!test-add))



(test-smatch "dhash expands into code to lookup key->value and vice versa"
  '(do
    (setup-autosave id-docs* (table))
    (setup-autosave doc-ids* (table))
    (setup-autosave doc-id-nils* (table))
    (def create-doc-id (doc) (list 0))
    (def set-doc-id (doc)
      (let id (create-doc-id doc)
        (if id
          (= (doc-ids* doc) id)
          (= (doc-id-nils* doc) t))
        (update id-docs* id rcons doc)
        id))
    (def doc-id (doc)
      (and (no (doc-id-nils* doc))
           (or (doc-ids* doc)
               (set-doc-id doc))))
    (def id-doc (id)
      (id-docs* id))
    (def doc-id? (doc)
       (doc-ids* doc)))

  (macex1 '(dhash doc id "1-1" (list 0))))

(= b-as* (table) a-bs* (table))
(dhash a b "1-1"
  (cadr (coerce a 'cons)))
(a-b "cat")
(a-b "dog")
(a-b "mat")
(test-iso "code generated by dhash works with rcons policy"
  '("mat" "cat")
  (b-a #\a))

(= b-as* (table) a-bs* (table))
(dhash a b "1-1"
  (cadr (coerce a 'cons))
  replace)
(a-b "cat")
(a-b "dog")
(a-b "mat")
(test-iso "code generated by dhash works with replace policy"
  "mat"
  (b-a #\a))

(= b-as* (table) a-bs* (table))
(dhash a b "1-1"
  (cadr (coerce a 'cons))
  or=fn)
(a-b "cat")
(a-b "dog")
(a-b "mat")
(test-iso "code generated by dhash works with or= policy"
  "cat"
  (b-a #\a))

(= b-as* (table))
(update b-as* #\a rcons 3)
(test-iso "update writes to table"
  (obj #\a (list 3))
  b-as*)
(update b-as* #\a rcons 1)
(test-iso "update rcons works"
  (obj #\a '(1 3))
  b-as*)
(update b-as* #\a replace 0)
(test-iso "update replace works"
  (obj #\a 0)
  b-as*)
(update b-as* #\a or=fn 343)
(test-iso "update or=fn doesn't replacing existing"
  (obj #\a 0)
  b-as*)
(update b-as* #\a replace nil)
(update b-as* #\a or=fn 3)
(test-iso "update or=fn sets if unset"
  (obj #\a 3)
  b-as*)



(shadowing buffered-exec-delay* 0
  (persisted a* (table))
  (= (a* 3) 4)
  (shadow-autosaved)
  (= a* (table))
  (= (a* 5) 6)
  (unshadow-autosaved)
  (= (a* 5) 6)

  (prn "   waiting for autosave before next test")
  (until (empty buffered-execs*)
    (sleep 1))
  (let dummy (table)
    (test-iso "shadowing and unshadowing doesn't interfere with persistence of the original variable"
      (obj 3 4 5 6)
      (fread (most-recent-snapshot-name a*) dummy))))

))
