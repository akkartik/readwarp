(= comics-buttons* (list next-button))
(= comics-widgets* (list facebook-widget twitter-widget reddit-widget google-widget))

; trailing slash required by subdomain proxying
(defop comics/ req
  (reader req choose-from-comics comics-buttons* comics-widgets*))

(defop comics/docupdate req
  (docupdate-core current-user.req req choose-from-comics
                  comics-buttons* comics-widgets*))

(def choose-from-comics(user station lastdoc)
  (randpick
    preferred-prob*     (choose-from 'recent-comics-preferred
                                     (keep (andf
                                             recent?
                                             [preferred? (station!sites _)
                                                         userinfo*.user!clock])
                                           (group-feeds* "Comics"))
                                     user station
                                     recent-and-well-cleaned)
    preferred-prob*     (choose-from 'comics-preferred
                                     (keep [preferred? (station!sites _)
                                                       userinfo*.user!clock]
                                           (group-feeds* "Comics"))
                                     user station)
    1.01                (choose-from 'recent-comics
                                     (keep recent?
                                       (group-feeds* "Comics"))
                                     user station
                                     recent-feed-predicate)
    1.01                (choose-from 'comics
                                     (group-feeds* "Comics")
                                     user station)))
