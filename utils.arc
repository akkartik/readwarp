(mac init args
  `(unless (bound ',(car args))
     (= ,@args)))

(mac ret (var val . body)
 `(let ,var ,val ,@body ,var))

(mac ifcall(var)
  `(if (bound ',var)
     (,var)))

(mac awhile(expr . body)
  `(whilet it ,expr
    ,@body))

(mac forever body
  `(awhile t ,@body))

(def transform(l . fl)
  (let ans l
    (each f fl
      (zap f ans))
    ans))

(mac before-exec(fnname args . body)
  `(let old ,fnname
      (def ,fnname ,args
        ,@body
        (old ,@args))))

(mac after-exec(fnname args . body)
  `(let old ,fnname
      (def ,fnname ,args
        (let result (old ,@args)
          ,@body
          result))))

(= buffered-execs* (table))
(def buffered-exec(f (o delay 10))
  (or= buffered-execs*.f
       (thread (sleep delay) (wipe buffered-execs*.f) (f))))

(def kwargs(args-and-body (o defaults))
  (let (kws body) (split-by args-and-body ':do)
    (list (fill-table (listtab:pair defaults) kws)
          (cdr body))))

(def extract-car(block test)
  (if (test*.test car.block)
    `(,(car block) ,(cdr block))
    `(nil ,block)))

(def test*(test)
  (if (isa test 'fn)   test
      (isa test 'sym)  [isa _ test]
                       [is _ test]))



(def id(x) x)

(def blank?(elem)
  (or no.elem empty.elem))

(mac nrem(f l)
  `(zap [rem ,f _] ,l))
(mac nkeep(f l)
  `(zap [keep ,f _] ,l))
(mac nmap(f l)
  `(zap [map ,f _] ,l))
(mac nmaptable(f tab)
  `(each k (keys ,tab)
      (zap ,f (,tab k))))

(def zip l
  (if (all acons l)
    (cons (map car l)
      (apply zip (map cdr l)))))

(def zipmax l
  (if (some acons l)
    (cons (map car l)
      (apply zipmax (map cdr l)))))

(def cdrs(n l)
  (if (is n 0)
    (list l)
    (cons l (cdrs (- n 1) (cdr l)))))

(def nctx(n l)
  (apply zipmax (cdrs (- n 1) l)))

(def deltas(l)
   (if (cdr l)
     (let (a b . rest) l
       (cons (- b a) (deltas (cons b rest))))))

(def mean(l)
  (if l
    (/ (apply + l) (len l))))

(def sum-of-squares(l)
  (apply + (map [* _ _] l)))

(def stddev(l)
  (iflet mu (mean l)
    (sqrt (- (/ (sum-of-squares l) (len l)) (* mu mu)))))

(def log10(n)
  (/ (log n) (log 10)))

(def inverse(t)
  (w/table t2
    (each key (keys t)
      (let val (t key)
        (if (acons val)
          (each v val
            (add-to (t2 key) v)))
          (add-to (t2 key) val)))
    t2))

(def split-by(seq delim)
  (case type.seq
    cons    (split seq (or (pos delim seq) (len seq)))
    string  (split seq (or (posmatch delim seq) (len seq)))
            (err "bad type for split-by")))

(mac add-to(l v)
  `(push ,v ,l))
(mac add-to-back(l v)
  `(= ,l (join ,l (list ,v))))

(def cons* body
  (if (cdr body)
    (cons (car body)
          (apply cons* (cdr body)))
    (car body)))

(def randpos(l)
  (if l
    (l (rand:len l))))

(def sorted(t f)
  (sort (compare > f:cadr) (tablist t)))

(mac append(a b)
  `(= ,a (+ ,a ,b)))

(def intersect(l1 l2)
  (keep [pos _ l2] l1))

(def common(l)
  (if (no:cdr l)
    car.l
    (reduce intersect l)))

(def aboutnmost(n l (o f id))
  (withs (initans (firstn n (sort-by f l))
          top (last initans)
          fill (keep [and _ (iso (f _) (f top))] l))
    (dedup (+ initans fill))))

(def most-skipping-nils(f args)
  (most f (rem nil args)))

(def bound-and-sort(l f thresh)
  (sort-by f (keep [> (f _) thresh] l)))

(def dedup-by(f l)
  (with (done (table)
         ans ())
    (each elem l
      (unless (done f.elem)
        (= (done f.elem) t)
        (push elem ans)))
    (rev ans)))

; every with progress indicator
(mac everyp(var l iters . body)
  (w/uniq ls
    `(let ,ls ,l
       (prn:len ,ls)
       (on ,var ,l
         (if (is 0 (remainder index ,iters))
           (prn index " " ,var))
         ,@body))))



(def pair?(l)
  (and (acons l)
       (acons:cdr l)
       (no:acons:cddr l)))

(def alist? (l)
  (and (acons l)
       (all pair? l)))

(def coerce-tab(tab)
  (if
    (isa tab 'table)  tab
    (alist? tab)      (listtab tab)
    (acons tab)       (listtab:pair tab)
                      (table)))

(def converting-tablists(l)
  (if (alist? l)
    (listtab2 l)
    l))

(def listtab2(al)
  (let h (table)
    (map (fn ((k v)) (= (h k) (converting-tablists v)))
         al)
    h))

(def read-nested-table((o i (stdin)) (o eof))
  (let e (read i eof)
    (if (alist e) (listtab2 e) e)))

(def tablist2(h)
  (if (isa h 'table)
    (accum a (maptable (fn (k v) (a (list k (tablist2 v)))) h))
    h))

(def write-nested-table(h (o o (stdout)))
  (write (tablist2 h) o))

(def merge-tables tables
  (let ans (table)
    (each tab tables
      (maptable (fn(k v) (= ans.k v)) coerce-tab.tab))
    ans))

(def read-json-table(filename)
  (on-err (fn(ex) (table))
          (fn()
            (w/infile f filename (json-read f)))))



(def index(test seq (o start 0))
  (or (pos test seq start)
      -1))

(def safecut(seq start (o end (len seq)))
  (if seq
    (cut seq (min start (len seq)) (min end (len seq)))
    seq))

(def posmatchall(pat seq (o start 0))
  (iflet ind (posmatch pat seq start)
    (cons ind (posmatchall pat seq (+ ind (len pat))))))

(def slurp(f (o sep "\n"))
  (if (isa f 'string)
    (w/infile file f (slurp file sep))
    (let ans ""
      (whiler line (readline f) nil
              (if (blank ans)
                (= ans line)
                (zap [string _ sep line] ans)))
      (if (~iso sep "\n")
        (subst sep "\n" ans)
        ans))))

(= re-timestamp* "[A-Z][a-z]{2} +[A-Z][a-z]{2} +[0-9]+ +[0-9]{2}:[0-9]{2}:[0-9]{2} +[A-Z]{3} +[0-9]{4}")
(= re-html-tag* "<[^>]*>")
(= re-html-entity* "&[#a-zA-Z0-9]{0,5};")
(def html-strip(doc)
  (transform doc
    [r-strip _
      "<!--.*-->"
      "<script.*</script>"
      "<style.*</style>"]
    [gsub _
      (r "\\s+") " "
      (r re-html-tag*) ""
      (r re-html-entity*) ""]))
(def html-slurp(f)
  (html-strip:slurp f))

(def canonicalize(word)
  (downcase:stem (gsub word (r "'.*") "")))

(def splitstr(s pat (o ind 0))
  (iflet start (posmatch pat s ind)
    (let end (+ start (len pat))
      (if (> start ind)
        (cons (cut s ind start) (splitstr s pat end))
        (splitstr s pat end)))
    (list (cut s ind))))

(def rmpat(doc begin end)
  (with (s (posmatch begin doc)
         e (posmatch end doc))
    (if (and s e)
      (let sk (cut doc s (+ e (len end)))
        (subst "" sk doc)))))

(def r-strip(doc . patlist)
  (let ans doc
    (each pat patlist
      (= ans (r-strip-sub ans pat)))
    ans))

(def r-strip-sub(doc pat)
  (with ((begin end) (splitstr pat ".*"))
    (iflet newdoc (rmpat doc begin end)
      (r-strip newdoc pat)
      doc)))

(def has-alpha?(s)
  (not (is #f (m (r "[A-Za-z]") s))))

(mac conscar(a l)
  `(= ,l (cons (cons ,a (car ,l)) (cdr ,l))))

(def partition(s (o f whitec))
  (with (state -1
         ans '())
    (each c s
      (let newstate (f c)
        (if (is newstate state)
          (= ans (cons (+ (car ans) c) (cdr ans)))
          (push (+ "" c) ans))
        (= state (f c))))
    (rev ans)))

(with (NEVER-WORD* ",;\"![]() \n\t\r"
       MAYBE-WORD* ".'=-/:&?")
  (def charclass(c)
    (let c (coerce c 'string)
      (if
        (posmatch c NEVER-WORD*)  0
        (posmatch c MAYBE-WORD*)  1
                                  2)))

  (def partition-words(s)
    (unless (blank s)
      (withs (firstchar (s 0)
              ans (list (list firstchar))
              state (charclass firstchar))
        (each (last curr next) (nctx 3 (coerce s 'cons))
          (if curr
            (let newstate (charclass curr)
              (if (is newstate 1)
                (if (or (whitec last) (whitec next))
                  (= newstate 0)
                  (= newstate 2)))
              (if
                (is newstate state) (conscar curr ans)
                                    (push (list curr) ans))
              (= state newstate))))
        (rev:map [coerce (rev _) 'string] ans)))))

(mac sub-core(f)
  (w/uniq (str rest)
     `(fn(,str . ,rest)
          (let s ,str
            (each (pat repl) (pair ,rest)
                  (= s ($(,f pat s repl))))
            s))))
(= sub (sub-core regexp-replace))
(= gsub (sub-core regexp-replace*))

(def regexp-escape(word)
  (gsub word
    (r "([+*^$])") "\\\\\\1"))

(def int2(n)
  (if n
    (coerce n 'int)
    0))



(def sort-by(f l)
  (rm-tags (sort-by-tag (add-tags f l))))

(def max-by(f l)
  (max-by-tag:add-tags f l))

(def sort-by-tag(l)
  (sort (compare > cdr) (keep cdr l)))

(def max-by-tag(l)
  (let (max maxval) (list nil nil)
    (each (curr . v) (keep cdr l)
      (if (or no.maxval (> v maxval))
        (= max curr maxval v)))
    max))

(def add-tags(f l)
  (map [cons _ (f _)] l))

(def rm-tags(l)
  (map car l))

(def tags-matching(v l)
  (map cdr (keep [iso (car _) v] l)))

(def add-index-tags(l)
   (add-index-tags-sub l))
(def add-index-tags-sub(l (o x 0))
   (if (acons l)
     (cons (cons (car l) x)
           (add-index-tags-sub (cdr l) (++ x)))))



(def p(s)
  (write s)
  (prn)
  s)

(include "arctap.arc")
(def tests()
  (each file (dir ".")
    (if (and (posmatch ".arc.t" file)
             (~litmatch "." file))
      (include file))))

(mac rotlog(var msg)
  `(do
     (push ,msg ,var)
     (= ,var (firstn 100 ,var))))

(def filenames(cmd)
  (tokens:slurp:pipe-from cmd))

(mac each-fifo(var fifo . body)
  (prn body)
  `(forever:each ,var (tokens:slurp ,fifo)
      ,@body))

(def Set args
  (w/table ans
    (each k args
      (= (ans k) t))))

(mac w/prfile(file . body)
  (w/uniq outf
    `(w/outfile ,outf ,file
      (w/stdout ,outf
        ,@body))))

(= maintenance-tasks* ())
(mac periodic-maintenance(maintenance-task . body)
  `(do
     (push (quote ,maintenance-task) maintenance-tasks*)
     (do1
       ((fn() ,@body))
       (pop maintenance-tasks*))))

(def maintenance-task()
  (if (acons maintenance-tasks*)
    (eval (car maintenance-tasks*))))

(= plurals* (table))
(def plural-of(s)
  (or (plurals* s)
      (+ s "s")))

(mac collect(body)
  (w/uniq fp
    `(let ,fp (outstring)
      (w/stdout ,fp ,body)
      (inside ,fp))))

(def time-ago(s)
  (- (seconds) s))



(def curr-path(f)
  (+ ($ start-dir*) f))

(mac load-scheme(f)
  `($ (require (file ,(curr-path f)))))

(mac load-ffi(name f)
  `($ (define ,name (ffi-lib ,(curr-path f)))))
