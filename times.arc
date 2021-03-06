(= times* (table))

(mac deftimed(name args . body)
  `(do
     (def ,(symize string.name "_core") ,args
        ,@body)
     (def ,name ,args
      (let t0 (msec)
        (ret ans ,(cons (symize string.name "_core") args)
          (update-time ,string.name t0))))))

(proc update-time(name t0)
  (or= times*.name (list 0 0))
  (with ((a b)  times*.name
         timing (- (msec) t0))
    (= times*.name
       (list
         (+ a timing)
         (+ b 1)))))

(def print-times()
  (prn "gc " (current-gc-milliseconds))
  (each (name time) times*
    (prn name " " time)))
