def sortedKeys(h):
  l = h.keys()
  l.sort(cmp=lambda x,y: -cmp(h[x], h[y]))
  return l

def isa(var, type):
  return var.__class__.__name__ == type

import re
def urlToFilename(url):
  return re.sub(r'[^a-zA-Z0-9]', '_', url)
