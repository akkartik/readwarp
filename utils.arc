(mac once-only (names . body)
  (withs (names (check names alist (list names))
          gensyms (map1 [uniq] names))
    `(w/uniq ,gensyms
      `(with ,(list ,@(mappend list gensyms names))
        ,(with ,(mappend list names gensyms)
          ,@body)))))

(mac extend (name arglist test . body)
  (w/uniq args
    `(let orig ,name
       (= ,name
          (fn ,args
            (if (apply (fn ,arglist ,test) ,args)
              (apply (fn ,arglist ,@body) ,args)
              (apply orig ,args)))))))



(mac init args
  `(unless (bound ',(car args))
     (= ,@args)))

(= neither nor)

(mac ifcall(var)
  `(when (bound ',var)
     (,var)))

(mac pushif(elem ls)
  `(aif ,elem
     (push it ,ls)))

(mac firsttime(place . body)
  `(unless ,place
     ,@body
     (set ,place)))

(mac proc(name args . body)
  `(def ,name ,args ,@body nil))

(mac ret(var val . body)
 `(let ,var ,val ,@body ,var))

(mac findg(generator test)
  (w/uniq (ans count)
    `(ret ,ans ,generator
       (let ,count 0
         (until (or (,test ,ans) (> (++ ,count) 10))
            (= ,ans ,generator))
         (unless (,test ,ans)
           (= ,ans nil))))))

(mac pipe-to(dest . body)
  `(fromstring
     (tostring ,@body)
     ,dest))

; counterpart of only: keep retrying until expr returns something, then apply f to it
(mac always(f expr)
  `(,f (findg ,expr ,f)))

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
              (ret result (old ,@args)
                ,@body)))))

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
       (thread "buffered" (sleep buffered-exec-delay*) (wipe buffered-execs*.f) (f))))

(mac wait(var)
  `(until ,var))

(mac timeout-exec (timeout . body)
  (w/uniq (done-flag thread-var)
    `(withs (,done-flag nil
             ,thread-var (new-thread "bound"
                           (fn()
                             (after*
                               ,@body
                              :do
                               (set ,done-flag)))))
       (thread "timeout2"
         (sleep ,timeout)
         (unless (dead ,thread-var)
           (w/stdout (stderr)
              (prn "Timeout"))
           (kill-thread ,thread-var)
           (set ,done-flag)))
       (wait ,done-flag))))

(let old new-thread
  (def new-thread(name f)
    (let t0 (msec)
      (old name
        (fn()
          (ret ans (f)
            (srvlog 'times sym.name (- (msec) t0))))))))

(mac log-time(name . body)
  (w/uniq t0
    `(let ,t0 (msec)
       ,@body
       (srvlog 'times ',name (- (msec) ,t0)))))



; helper for keyword args separated from body by :do
(def kwargs(args-and-body (o defaults))
  (let (kws body) (split-by args-and-body ':do)
    (list (fill-table (listtab:pair defaults) kws)
          (cdr body))))

; def to be called with mandatory keyword args
(mac defk(fnname args . body)
  `(def ,fnname params
    (let paramtab (listtab pair.params)
      (withs ,(with-bindings-from-table args paramtab)
        ,@body))))

; def with fake kwargs that still need to be ordered right
(mac defc(fnname args . body)
  (let subfn (symize stringify.fnname "-sub")
    `(do
       (def ,subfn ,args
          ,@body)
       (mac ,fnname params
          (if (~check-kwargs params ',args)
            (err "" params " doesn't match " ',args)
            ,(list 'apply subfn `(rem colonsym params)))))))

(def extract-car(block test)
  (if (test*.test car.block)
    `(,(car block) ,(cdr block))
    `(nil ,block)))

(def test*(test)
  (if (isa test 'fn)   test
      (isa test 'sym)  [isa _ test]
                       [is _ test]))

(mac with-bindings-from-table(args tabname)
  `(mappend [cons _ (list:list ',tabname `(quote ,_))] ,args))

(def check-kwargs(args prototype)
  (is prototype (map strip-colon:car (pair args))))



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

(mac nslowrot(l)
  `(when ,l (= ,l (+ (cdr ,l) (list (car ,l))))))



; random elem in from that isn't already in to (and satisfies f)
(def random-new(from to (o f))
  (ret ans nil
    (let counter 0
      (until (or ans (> (++ counter) 10))
        (let curr randpos.from
          (when (and (~pos curr to)
                     (or no.f
                         (f curr)))
            (= ans curr)))))))

(mac randpick args
  (w/uniq (x ans)
    `(with (,x (rand)
            ,ans nil)
      ,@(accum acc
         (each (thresh expr) (pair args)
           (acc `(when (and (no ,ans)
                            (< ,x ,thresh))
                   (= ,ans ,expr))))
         (acc ans)))))

(def shuffle(ls)
  (let n len.ls
    (ret ans copy.ls
      (repeat (/ n 2)
        (swap (ans rand.n) (ans rand.n))))))



(def zip ls
  (apply map list ls))

(def partition(l f)
  (when l
    (let (a b) (partition cdr.l f)
      (if (f car.l)
        (list (cons car.l a) b)
        (list a (cons car.l b))))))

(def map-every(f l n (o offset 0))
  (map [let (v . i) _
         (if (is offset (remainder i n))
           (f v)
           v)]
    (add-index-tags l)))

(def sliding-window(n xs)
  (accum a
    (a (firstn n xs))
    (whilet xs (cdr xs)
      (a (firstn n xs)))))

(def deltas(l)
   (when (cdr l)
     (let (a b . rest) l
       (cons (- b a) (deltas (cons b rest))))))

(def mean(l)
  (when l
    (/ (apply + l) (len l))))

(def sum-of-squares(l)
  (apply + (map [* _ _] l)))

(def stddev(l)
  (whenlet mu (mean l)
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
  (when l
    (l (rand:len l))))

(def sorted(t f)
  (sort (compare > f:cadr) (tablist t)))

(mac append(a b)
  `(= ,a (+ ,a ,b)))

(def intersect(l1 l2)
  (keep [pos _ l2] l1))

(def set-subtract(l1 l2)
  (rem [pos _ l2] l1))

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
         (when (is 0 (remainder index ,iters))
           (prn " " index " " ,var))
         ,@body))))

(def rewrite(new old form)
  (if
    (is form old) new
    (~acons form) form
                  (map [rewrite new old _] form)))



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
  (if no.l      (table)
      alist?.l  (listtab2 l)
                l))

(def listtab2(al)
  (let h (table)
    (map (fn ((k v)) (= (h k) (converting-tablists v)))
         al)
    h))

(def read-nested-table((o i (stdin)) (o eof))
  (let e (read i eof)
    (if no.e        (table)
        (alist? e)  (listtab2 e)
                    e)))

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

; freq without any atomic operations
(def freqcounts(l f (o n 1))
  (if (no cdr.l)
    (prn car.l " " n)
    (if (is (f car.l) (f cadr.l))
      (freqcounts cdr.l f (+ n 1))
      (do
        (prn car.l " " n)
        (freqcounts cdr.l f)))))

(def max-freq(l)
  (max-key freq.l))

(mac inittab (place . args)
  `(do (or= ,place (table))
       (init-table ,place (list ,@args))))

; XXX redundantly computed vals
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
  (whenlet ind (posmatch pat seq start)
    (cons ind (posmatchall pat seq (+ ind (len pat))))))

(def slurp(f (o sep "\n"))
  (if (isa f 'string)
    (w/infile file f (slurp file sep))
    (let ans ""
      (whilet line (readline f)
        (if (blank ans)
          (= ans line)
          (zap [string _ sep line] ans)))
      (if (~iso sep "\n")
        (subst sep "\n" ans)
        ans))))

(def canonicalize(word)
  (stem:downcase (gsub word (r "\"|'.*") "")))

(def split-urls(s)
  (tokens s [pos _ ":/."]))

(def has-alpha?(s)
  (not (is #f (m (r "[0-9A-Za-z]") s))))

(def words(s)
  (on-err
    (fn(ex) (erp "B: " s " " details.ex))
    (fn() (keep has-alpha? tokens.s))))

(def maybe-enclose(before payload after test)
  (if (test payload)
    (+ before payload after)
    payload))

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
    int.n
    0))

(def uncamelcase(word)
  (gsub word
    (r "([a-z])([A-Z])") "\\1 \\2"))

(def colonsym(sym)
  (headmatch ":" (stringify sym)))
;? (mac colonsym(sym)
;?   `(headmatch ":" (stringify ',sym)))

(def strip-colon(sym)
  (let ans stringify.sym
    (if (is ans.0 #\:)
      (= ans (cut ans 1)))
    symize.ans))



(def sort-by(f l)
  (rm-tags (sort-by-tag (add-tags f l))))

(def max-by(f l)
  (max-by-tag:add-tags f l))

(def sort-by-tag(l)
  (sort (compare > cdr) (keep cdr l)))

(def max-by-tag(l)
  (let (max maxval) (list nil nil)
    (each (curr . v) (keep cdr l)
      (when (or no.maxval (> v maxval))
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
   (when acons.l
     (cons (cons car.l x)
           (add-index-tags-sub cdr.l ++.x))))



(def p(s)
  (write s)
  (prn)
  s)

(def erp args
  (w/stdout (stderr)
    (apply prn args)))

(def gc()
  ($:collect-garbage))

(def maybe(msg)
  (or msg ""))

(= performance-vector ($:make-vector 10))
(proc prn-stats((o msg))
  ($:vector-set-performance-stats! _performance-vector)
  (erp maybe.msg performance-vector))

(proc prn-stats2((o msg))
  (freqcounts
    (sort-by car (rem [dead cadr._] threads*))
    car))

(def threads(name)
  (map cadr (keep [is car._ name] threads*)))

(include "arctap.arc")
(proc tests()
  (after*
    (= test-failures* 0)
    (each file (dir ".")
      (when (and (posmatch ".arc.t" file)
                 (~litmatch "." file))
        (include file)))
  :do
    (prn:plural test-failures* "failure")))

(def test-mode()
  (~empty (getenv "TEST")))

(def l(f)
  (include:+ stringify.f ".arc"))
(def test(f)
  (after*
    (= test-failures* 0)
    (include:+ stringify.f ".arc.t")
  :do
    (prn:plural test-failures* "failure")))

(def dump-stack-trace(msg)
  (w/stdout (stderr)
    (prn msg)
    ($:print (continuation-mark-set->context (current-continuation-marks)))))

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
    `(w/appendfile ,outf ,file
      (w/stdout ,outf
        ,@body))))

(mac nopr body
  `(w/prfile "/dev/null"
      ,@body))

(= maintenance-tasks* ())
(mac periodic-maintenance(maintenance-task . body)
  `(do
     (push (quote ,maintenance-task) maintenance-tasks*)
     (do1
       ((fn() ,@body))
       (pop maintenance-tasks*))))

(def maintenance-task()
  (when acons.maintenance-tasks*
    (eval car.maintenance-tasks*)))

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



(def curr-path(f)
  (+ ($ start-dir*) f))

(mac load-scheme(f)
  `($ (require (file ,(curr-path f)))))

(mac load-ffi(name f)
  `($ (define ,name (ffi-lib ,(curr-path f)))))

($:xdef getenv getenv)
