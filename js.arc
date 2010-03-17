(mac a-onclick(url . body)
  `(tag (a href "#" onclick ,url)
    ,@body))

(def jsquotes(s)
  (if (or (headmatch "'" s)
          (endmatch "'" s))
    s
    (+ "'" s "'")))

(def maybe-flink(f)
  (jsquotes
    (if (isa f 'fn)
      (flink f)
      f)))

(def inline(id f)
  (+ "inline('" id "', "
     maybe-flink.f
     ");"))

(def pushHistory(sname doc params)
  (+ "pushHistory('" jsesc.sname "', '" jsesc.doc "', " params ")"))

(def confirm(msg s)
  (+ "if(confirm('" msg "')){"
       s
     "}"))

(def addjsarg(l arg)
  (+ "'" l "&' + "
     arg))

(def check-with-user(msg param)
  (+ "'" param "='" " + "
     "confirm('" jsesc.msg "')"))

(mac w/jslink(attr-generator . body)
  `(tag (a ,@(eval attr-generator))
    ,@body))

(mac update-dom args
  `(let params (listtab:pair ',args)
    (list
      'href "#"
      'style (params ':style)
      'onclick (update-onclick params))))

(def update-onclick(params)
  (or (params ':onclick)
      (inline (params ':into) (params ':with))))

(def jsdo args
  (apply + args))
