(mac once-only (names . body)
  (withs (names (check names alist (list names))
          gensyms (map1 [uniq] names))
    `(w/uniq ,gensyms
      `(with ,(list ,@(mappend list gensyms names))
        ,(with ,(mappend list names gensyms)
          ,@body)))))

(mac init args
  `(unless (bound ',(car args))
     (= ,@args)))

(mac ifcall(var)
  `(if (bound ',var)
     (,var)))

(mac pushif(elem ls)
  `(aif ,elem
     (push it ,ls)))

(mac proc(name args . body)
  `(def ,name ,args ,@body nil))

(mac ret(var val . body)
 `(let ,var ,val ,@body ,var))

(mac awhile(expr . body)
  `(whilet it ,expr
    ,@body))

(mac forever body
  `(while t ,@body))

(mac disabled body
  `(when nil ,@body))

(mac enabled body
  `(when t ,@body))

(mac letloop(var init term inc . body)
  `(let ,var nil
     (loop (= ,var ,init) ,term ,inc
        ,@body)))

(mac after* block
  (let (body finally) (split-by block ':do)
    `(after
       (do ,@body)
       (do ,@finally))))

; backtracking let: after body return init unless postcond
(mac blet(var init postcond . body)
  (w/uniq orig
    `(withs (,orig ,init
             ,var ,orig)
       ,@body
       (if ,postcond
         ,var
         ,orig))))



(mac redef(var expr)
  `(after*
     (set disable-redef-warnings*)
     (= ,var ,expr)
    :do
     (wipe disable-redef-warnings*)))

;; dynamic scope when writing tests
(mac shadow(var expr)
  (let stack (globalize stringify.var "-stack")
    `(do
       (init ,stack ())
       (push ,var ,stack)
       (redef ,var ,expr))))

(mac unshadow(var)
  (let stack (globalize stringify.var "-stack")
    `(do
      (if (or (~bound ',stack)
              (empty ,stack))
         (prn "*** couldn't unshadow " ',var)
         (redef ,var (pop ,stack)))
      nil)))

(mac shadowing(var expr . body)
  `(after*
     (shadow ,var ,expr)
     ,@body
    :do
     (unshadow ,var)))



(mac before-exec(fnname args . body)
  `(let old ,fnname
      (redef ,fnname
             (fn ,args
                ,@body
                (old ,@args)))))

(mac after-exec(fnname args . body)
  `(let old ,fnname
      (redef ,fnname
            (fn ,args
              (let result (old ,@args)
                ,@body
                result)))))

(mac scoped-extend(var . body)
  (let stack (globalize stringify.var "-stack")
    `(after
       (init ,stack ())
       (push ,var ,stack)
       ,@body
      :do
       (redef ,var (pop ,stack)))))



(= buffered-exec-delay* 10)
(= buffered-execs* (table))
(def buffered-exec(f)
  (or= buffered-execs*.f
       (thread (sleep buffered-exec-delay*) (wipe buffered-execs*.f) (f))))

(mac wait(var)
  `(until ,var))

(mac timeout-exec (timeout . body)
  (w/uniq (done-flag thread-var)
    `(withs (,done-flag nil
             ,thread-var (new-thread
                           (fn()
                             (after*
                               ,@body
                              :do
                               (set ,done-flag)))))
       (thread
         (sleep ,timeout)
         (unless (dead ,thread-var)
           (w/stdout (stderr)
              (prn "Timeout"))
           (kill-thread ,thread-var)
           (set ,done-flag)))
       (wait ,done-flag))))



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

(def transform(l . fl)
  (let ans l
    (each f fl
      (zap f ans))
    ans))

(mac nrem(f l)
  `(zap [rem ,f _] ,l))
(mac nkeep(f l)
  `(zap [keep ,f _] ,l))
(mac nmap(f l)
  `(zap [map ,f _] ,l))
(mac nmaptable(f tab)
  `(each k (keys ,tab)
      (zap ,f (,tab k))))

(def zip ls
  (apply map list ls))

(def sliding-window(n xs)
  (accum a
    (a (firstn n xs))
    (whilet xs (cdr xs)
      (a (firstn n xs)))))

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
  (if (~cdr l)
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
           (prn " " index " " ,var))
         ,@body))))



(def pair?(l)
  (and (acons l)
       (acons:cdr l)
       (~acons:cddr l)))

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

(def first-key(tb)
  (car keys.tb))
(def first-keys(n tb)
  (firstn n keys.tb))
(def len-keys(tb)
  (len keys.tb))
(def first-value(tb)
  (tb first-key.tb))
(def first-pair(tb)
  (car tablist.tb))
(def max-key(tb)
  (max-by tb keys.tb))
(def max-val(tb)
  (max:add-tags tb keys.tb))

(def freq(l)
  (ret ans (table)
    (each o l
      (++ (ans o 0)))))

(def max-freq(l)
  (max-key freq.l))

(mac inittab (place . args)
  `(do (or= ,place (table))
       (init-table ,place (list ,@args))))

(def init-table (table data)
  (each (k v) (pair data) (or= (table k) v))
  table)



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
  (erp ".")
  (ret ans (downcase:stem (gsub word (r "'.*") ""))
    (erp "+")))

(def splitstr(s pat (o ind 0))
  (iflet start (posmatch pat s ind)
    (let end (+ start (len pat))
      (if (> start ind)
        (cons (cut s ind start) (splitstr s pat end))
        (splitstr s pat end)))
    (list (cut s ind))))

(def split-urls(s)
  (tokens s [pos _ ":/."]))

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

(def partition-words(s)
  (unless (blank s)
    (with (ans (list:list:s 0) state (charclass s.0))
      (each (prev curr next) (sliding-window 3 (coerce s 'cons))
        (when curr
          (let newstate (charstate curr prev next)
            (if (is newstate state)
                (push curr (car ans))
                (push (list curr) ans))
            (= state newstate))))
      (rev:map [coerce (rev _) 'string] ans))))

(with (never-word* ";\"![]() \n\t\r"
       maybe-word* ".,'=-/:&?")
  (def charclass(c)
    (if (find c never-word*)
          'never
        (find c maybe-word*)
          'maybe
          'always)))

(def charstate(c prev next)
  (caselet class (charclass c)
    maybe (if (or (whitec prev) (whitec next))
              'never
              'always)
          class))

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

(proc erp args
  (w/stdout (stderr)
    (apply prn args)))

(def gc()
  ($:collect-garbage))

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

(def render-date(s)
  (let d (date int.s)
    (+ "" d.0 "-" d.1 "-" d.2)))

(def l(f)
  (include:+ stringify.f ".arc"))
(def test(f)
  (include:+ stringify.f ".arc.t"))



(def curr-path(f)
  (+ ($ start-dir*) f))

(mac load-scheme(f)
  `($ (require (file ,(curr-path f)))))

(mac load-ffi(name f)
  `($ (define ,name (ffi-lib ,(curr-path f)))))



;; input table: key -> cluster of values
;; output table: value1, value2 -> affinity
;; affinity gets distributed between clusters
(def normalized-affinity-table(similarity-table)
  (w/table ans
    (each (e cluster) similarity-table
      (let n len.cluster
        (each v cluster
          (each v2 cluster
            (when (< v v2)
              (or= ans.v (table))
              (or= ans.v2 (table))
              (or= ans.v.v2 0)
              (zap [+ _ (/ 1.0 (- n 1))] ans.v.v2)
              (= ans.v2.v ans.v.v2))))))))
