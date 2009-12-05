($ (module keywords-ffi mzscheme
  (provide stem keywords)
  (require scheme/foreign)
  (unsafe!)
  (define extlib (ffi-lib "ext"))
  (define stem (get-ffi-obj "stem" extlib (_fun _string -> _string)))
  (define keywords (get-ffi-obj "keywords" extlib (_fun _string -> _string)))
))
($ (require 'keywords-ffi))

($ (xdef stem stem))
($ (xdef kwds keywords))

(def keywords(fname)
  (splitstr (kwds fname) ","))
