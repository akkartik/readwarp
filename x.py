import twython

twitter = twython.setup()
#? for elem in twitter.getUserTimeline(screen_name='akkartik', count=200):
#?   print elem['created_at'], '---', elem['text']

print len(twitter.getFriendsIDs(screen_name='scobleizer')['ids'])
