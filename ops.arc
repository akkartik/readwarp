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
