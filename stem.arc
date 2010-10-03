($ (module stem-ffi mzscheme
  (provide stem)
  (require scheme/foreign)
  (unsafe!)
  (define extlib (ffi-lib "ext"))
  (define stem (get-ffi-obj "stem" extlib (_fun _string -> _string)))
))
($ (require 'stem-ffi))

($ (xdef stem-sub stem))

(let stem-exceptions (obj "economy" "econom")
  (def stem(s)
    (or stem-exceptions.s (copy stem-sub.s))))
