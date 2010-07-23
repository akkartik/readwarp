(defop perftest req
  (unless is-prod.req
    (errsafe:wipe ustation.nil!current)
    (docupdate-core nil req)))



(init my-ip* "174.129.11.4")
(mac maintenance-op(name req . body)
  `(defop ,name ,req
    (when (is (,req 'ip) my-ip*)
      ,@body)))



(= daily-clears* nil)
(maintenance-op cleardailystats req
  (each f daily-clears*
    (eval.f)))

(mac daily-persisted(var val)
  `(do
     (persisted ,var ,val)
     (defreg ,(symize "clear-" var)() daily-clears*
        (= ,var ,val))))



(daily-persisted loggedin-users* (table))
(maintenance-op rusers req
  (let (returning new) (partition keys.loggedin-users* old-user)
    (prn "Newly signedup: " len.new)
    (prn)
    (prn "Returning: " returning)))
(after-exec current-user(req)
  (when (and userinfo*.result userinfo*.result!signedup)
    (set loggedin-users*.result)))

(def old-user(user)
  (or (no userinfo*.user!created)
      (< userinfo*.user!created
         (time-ago:* 60 60 24))))

(daily-persisted voting-stats* (table))
(after-exec mark-read(user d outcome g)
  (or= voting-stats*.user (table))
  (++ (voting-stats*.user outcome 0))
  (or= voting-stats*!total (table))
  (++ (voting-stats*!total outcome 0)))
(after-exec create-query(user query)
  (or= voting-stats*.user (table))
  (++ (voting-stats*.user 'askfors 0)))
(maintenance-op votingstats req
  (awhen voting-stats*!total
    (prn "TOTAL +" (it "4")
              " =" (it "2")
              " -" (it "1")))
  (each (user info) voting-stats*
    (unless (is 'total user)
      (prn user " +" (or (info "4") 0)
                " =" (or (info "2") 0)
                " -" (or (info "1") 0)
                " ?" (or info!askfors 0)))))
