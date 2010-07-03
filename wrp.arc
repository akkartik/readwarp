;To apache:
; RewriteCond %{HTTP_HOST} ^wrp.to$ [NC]
; RewriteRule ^/(.*)$ http://readwarp.com/url?id=$1 [L,R=301]

(def wrp(doc)
  (+ "http://wrp.to/" doc-hash.doc))

(def doc-hash(doc)
  (url-hash doc-url.doc))

(defop url req
  (prn:+
    "<html><head><meta http-equiv=\"refresh\" content=\"0;url="
    (hash-url:arg req 'id)
    "\"></head></html>"))

(dhash url hash "1-1"
  (gen-hash)
  or=fn)

(def gen-hash()
  (or= url-hashs*!curr "aaaaa"))
(after-exec gen-hash()
  (zap nexthash url-hashs*!curr))

(def nexthash(s)
  (string:rev:nextcharlist:rev:listify s))

(def nextcharlist(l)
  (when l
    (let x (nexthashchar car.l)
      (cons x
        (if (is x #\a)
          (nextcharlist cdr.l)
          cdr.l)))))

(def nexthashchar(c)
  ; a-z0-9
  (if
    (is c #\z)  #\A
    (is c #\Z)  #\0
    (is c #\9)  #\a
            ($.integer->char (+ 1 ($.char->integer c)))))
