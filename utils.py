def sortedKeys(h):
  l = h.keys()
  l.sort(cmp=lambda x,y: -cmp(h[x], h[y]))
  return l

def isa(var, type):
  return var.__class__.__name__ == type

import codecs
def slurp(f, encoding='utf-8'):
  return codecs.open(f, 'r', encoding).read()

import re
def urlToFilename(url):
  return re.sub(r'[^a-zA-Z0-9]', '_', url)

# http://stackoverflow.com/questions/375427/non-blocking-read-on-a-stream-in-python/1810703#1810703
import fcntl, os
def nonblockingOpen(filename):
  handle = open(filename)
  fd = handle.fileno()
  fl = fcntl.fcntl(fd, fcntl.F_GETFL)
  fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
  return handle
