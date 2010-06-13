(= startups-buttons* (list next-button))
(= startups-widgets* (list twitter-widget hackernews-widget google-widget))

; trailing slash required by subdomain proxying
(defop startups/ req
  (reader req choose-from-venture startups-buttons* startups-widgets*))

(defop startups/docupdate req
  (docupdate-core current-user.req req choose-from-venture
                  startups-buttons* startups-widgets*))

(def choose-from-venture(user station lastdoc)
  (randpick
    preferred-prob*     (choose-from 'recent-venture-preferred
                                     (keep (andf
                                             recent?
                                             [preferred? (station!sites _)
                                                         userinfo*.user!clock])
                                           (group-feeds* "Venture"))
                                     user station
                                     recent-and-well-cleaned)
    preferred-prob*     (choose-from 'venture-preferred
                                     (keep [preferred? (station!sites _)
                                                       userinfo*.user!clock]
                                           (group-feeds* "Venture"))
                                     user station)
    1.01                (choose-from 'recent-venture
                                     (keep recent?
                                       (group-feeds* "Venture"))
                                     user station
                                     recent-feed-predicate)
    1.01                (choose-from 'venture
                                     (group-feeds* "Venture")
                                     user station)))
