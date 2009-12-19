import sys, string
import fileinput

index = {}

lastfeed=None

def reset():
  global lastfeed, numurls, keywords
  if lastfeed: update_index()
#?   if lastfeed: print lastfeed, numurls, freqhist()

  keywords={}
  numurls=0

def update_index():
  ans = {}
  maxfreq = max(keywords.values())
#?   print lastfeed, maxfreq, keywords
  for key,value in keywords.items():
#?     if value in [0, 1]: continue
    if value < maxfreq/2: continue

    if not index.has_key(key):
      index[key] = []
    index[key].append(lastfeed)

def freqhist():
  ans = {}
  maxfreq = max(keywords.values())
  for key,value in keywords.items():
#?     if value in [0, 1]: continue
    if value < maxfreq/2: continue

    if not ans.has_key(value):
      ans[value] = []
    ans[value].append(key)

  return ans.items()

feeds = set()

for line in fileinput.input():
  words = string.translate(line, None, "()").split()
  feed = words[1]
  if feed != lastfeed:
    reset()
    lastfeed = feed
    feeds.add(feed)

  numurls += 1
  for word in words[2:]:
    if not keywords.has_key(word):
      keywords[word] = 0
    keywords[word] += 1
reset()

#? for k, v in index.items():
#?   if len(v) > 1:
#?     print k, len(v) #, v

feed_affinity = {}
for cluster in index.values():
  cluster.sort()
  n = len(cluster)
  if len(cluster) > 1:
    for f in cluster:
      for f2 in cluster:
        if f < f2:
          if not feed_affinity.has_key(f+f2):
            feed_affinity[f+' '+f2] = 0
          feed_affinity[f+' '+f2] += 1.0/(n-1)

for k, v in feed_affinity.items():
  print k, v
