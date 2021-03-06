(shadowing persisted-vars* ()
(shadowing snapshots-dir* "test-snapshots"
(system:+ "mkdir -p " snapshots-dir*)
(system:+ "rm " snapshots-dir* "/?s*.*")

(let quit-called nil
  (shadowing really-quit (fn() set.quit-called)
    (let var nil (save-snapshot var))
    (let var nil
      (load-snapshot var (table))
      (test-nil "nil file loads into nil"
        var))

    (let var (table) (save-snapshot var))
    (let var nil
      (load-snapshot var (table))
      (test-iso "empty table loads correctly"
        (table)
        var))

    (let var "abc" (save-snapshot var))
    (let var nil
      (load-snapshot var (table))
      (test-ok "load-snapshot bails on corrupted snapshot file"
               quit-called))))



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
        ()))
    (init foo-thread* (new-thread "foo" foo))
    (pushnew foo-thread* scan-registry*))
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
    (init foo-thread* (new-thread "foo" foo))
    (pushnew foo-thread* scan-registry*))
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
    (persisted id-docs* (table))
    (persisted doc-ids* (table))
    (persisted doc-id-nils* (table))
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

(= b-as* (table))
(update b-as* #\a rconsn.3 1)
(test-iso "update rconsn works like rcons at the start"
  (list 1)
  (b-as* #\a))
(update b-as* #\a rconsn.3 2)
(update b-as* #\a rconsn.3 3)
(test-iso "update rconsn works like rcons at the start - 2"
  (list 3 2 1)
  (b-as* #\a))
(update b-as* #\a rconsn.3 4)
(test-iso "update rconsn trims to n elems or under"
  (list 4 3 2)
  (b-as* #\a))
(update b-as* #\a rconsn.3 2)
(test-iso "update rconsn dedups"
  (list 4 3 2)
  (b-as* #\a))

(= b-as* (table))
(= last-popped* nil)
(= u3 (fixedq 3 [= last-popped* _]))
(update b-as* #\a u3 1)
(update b-as* #\a u3 2)
(update b-as* #\a u3 3)
(test-iso "update fixedq works like rcons at the start"
  '(3 2 1)
  (dl-elems:b-as* #\a))

(update b-as* #\a u3 4)
(test-iso "update fixedq trims to n elems or under"
  '(4 3 2)
  (dl-elems:b-as* #\a))

(test-iso "update fixedq operates on popped elem"
  1
  last-popped*)

))
