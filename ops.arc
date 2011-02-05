(const my-ip* "173.255.225.78")
(mac maintenance-op(name req . body)
  `(defop ,name ,req
    (when (is (,req 'ip) my-ip*)
      ,@body)))



(wipe daily-clears*)
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
(after-exec mark-read(user d)
  (or= voting-stats*.user (table))
  (++ (voting-stats*.user "2" 0)))
(after-exec vote(user d outcome)
  (or= voting-stats*.user (table))
  (++ (voting-stats*.user outcome 0))
  (or= voting-stats*!total (table))
  (++ (voting-stats*!total outcome 0)))
(maintenance-op votingstats req
  (awhen voting-stats*!total
    (prn "TOTAL +" (it "4" 0)
              " -" (it "1" 0)))
  (each (user info) voting-stats*
    (unless (is 'total user)
      (prn user " +" (info "4" 0)
                " =" (info "2" 0)
                " -" (info "1" 0)))))
