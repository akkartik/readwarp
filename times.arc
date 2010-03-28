(= times* (table))

(mac deftimed(name args . body)
  (w/uniq (arg)
    `(let arg 0
       (def ,(symize (stringify name) "_core") ,args
          ,@body)
       (def ,name ,args
        (let t0 (msec)
          (ret ans ,(cons (symize (stringify name) "_core") args)
            (update-time ,(stringify name) t0)))))))

(proc update-time(name t0)
  (or= times*.name (list 0 0))
  (with ((a b c)  times*.name
         timing   (- (msec) t0))
    (= times*.name
       (list
         (+ a timing)
         (+ b 1)))))

(def print_times()
  (prn "gc " (current-gc-milliseconds))
  (each (name time) (tablist times*)
    (prn name " " time)))
