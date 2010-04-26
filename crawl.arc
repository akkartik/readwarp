(include "www.arc")

; blocking IO
(def twitter-statuses(user)
  (w/instring f (get-url:+ "http://api.twitter.com/1/statuses/user_timeline/" user ".json?count=200")
    (json-read f)))

(def twitter-followee-ids(user)
  (w/instring f (get-url:+ "http://api.twitter.com/1/friends/ids.json?screen_name=" user)
    (json-read f)))

(def nonblocking-twitter-num-followees(user)
  (let a nil
    (async-exec a 3
      (len:twitter-followee-ids user))))
