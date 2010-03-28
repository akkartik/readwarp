(= times* (table))

(mac deftimed(name args . body)
  (w/uniq (arg)
    `(let arg 0
       (def ,(symize (stringify name) "_core") ,args
          ,@body)
       (def ,name ,args
        (withs (time0 (msec)
                ans ,(cons (symize (stringify name) "_core") args)
                time1 (msec))
          (or= (times* ,(stringify name)) (cons 0 0))
          (= (times* ,(stringify name))
             (cons
               (+ (car (times* ,(stringify name))) (- time1 time0))
               (+ 1 (cdr (times* ,(stringify name))))))
          ans)))))

(def print_times()
  (prn "gc " (current-gc-milliseconds))
  (each (name time) (tablist times*)
    (prn name " " time)))
