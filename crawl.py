import os, sys, re, traceback, time, pickle
import urlparse, urllib2, openanything
UrlOpener = urllib2.build_opener(openanything.SmartRedirectHandler())
import timeoutsocket
timeoutsocket.setDefaultSocketTimeout(20)

import feedparser, feedparser_extensions
from BeautifulSoup import BeautifulSoup
import json
from json_extensions import to_json

from utils import urlToFilename, nonblockingOpen

priority_crawl = nonblockingOpen('fifos/tocrawl')

canonical_url = {}
def loadUrlMap():
  global canonical_url
  if os.path.exists('snapshots/url_map'):
    with open('snapshots/url_map') as input:
      try:
        canonical_url = pickle.load(input)
      except KeyboardInterrupt:
        raise
      except:
        print 'Corrupt url map; first crawl will take forever'

def saveUrlMap():
  if len(canonical_url) > 0:
    with open('snapshots/url_map', 'w') as output:
      pickle.dump(canonical_url, output)

feedinfo = {}
def saveFeedInfo(fname):
  fname = 'snapshots/'+fname
  with open(fname+'.tmp', 'w') as output:
    json.dump(feedinfo, output, default=to_json)
  os.rename(fname+'.tmp', fname)

import shutil
backupTimestamp = str(time.time())
def backupFeedinfo():
  try: shutil.copyfile('snapshots/feedinfo', 'snapshots/feedinfo.'+backupTimestamp)
  except IOError: pass

def loadFeeds():
  ans = set()
  with open('feeds/All') as input:
    for line in input:
      yield line.rstrip()

def mungeUrl(url):
  ans = re.sub(r'#.*|\?(utm[^&]*&?)*$', '', url)
  if re.match(r'utm', ans): print ans
  return ans

def postprocessContents(s):
  return re.sub(r'</?font[^>]*>', '',
            re.sub(r'<br/?>\s*<br/?>', '<p/>', s))

def urlOpen(url):
  request = urllib2.Request(url)
  f = None
  try:
    f = UrlOpener.open(request)
    try:
      contentLength = f.info().get('Content-Length')
      if contentLength and float(contentLength) > 1024*1024:
        print 'that file is too big'
        return None, None
    except KeyboardInterrupt:
      raise
    except:
      traceback.print_exc(file=sys.stdout)
  except urllib2.HTTPError: 
    print "Adding user-agent"
    request.add_header('User-Agent', 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5')
    f = UrlOpener.open(request)
  except TypeError:
    if url[0:5] == 'https': return urlOpen('http'+url[5:])
    raise
  return (mungeUrl(f.url), postprocessContents(f.read()))

def absolutify(node, attr, url):
  if node.has_key(attr):
    old = node[attr]
    node[attr] = urlparse.urljoin(url, node[attr])

import magic
def goodFileType(f):
  type = magic.file(f)
  return type == 'data' or type.find('text') > -1

def crawlUrl(rurl, metadata):
  soup = None
  url = None
  if canonical_url.has_key(rurl):
    url = canonical_url[rurl]
  else:
    try:
      url, contents = urlOpen(rurl)
      if url == None: return
    except timeoutsocket.Timeout: return
    except TypeError: # timeoutsocket bug: sslwrap() argument 1 must be _socket.socket, not _socketobject
      print '!ssl'
      return

    canonical_url[rurl] = url

    soup = BeautifulSoup(contents)
    for node in soup.findAll(True):
      absolutify(node, 'href', url)
      absolutify(node, 'src', url)

  if not soup: return

  doc = urlToFilename(url)
  outfilename = 'urls/'+doc
  if not os.path.exists(outfilename+'.raw'):
    print repr(url)
    with open(outfilename+'.raw', 'w') as output:
      output.write(soup.renderContents())

  if not goodFileType(outfilename+'.raw'): # lose the podcasts
    os.unlink(outfilename+'.raw')
    return

  if not os.path.exists(outfilename+'.metadata'):
    metadata['url'] = url
    try:
      with open(outfilename+'.metadata', 'w') as output:
        json.dump(metadata, output, default=to_json)
    except KeyboardInterrupt:
      raise
    except:
      traceback.print_exc(file=sys.stdout)
      try: os.unlink(outfilename+'.metadata')
      except os.OSError: pass

    with open('fifos/crawl', 'w') as fifo:
      fifo.write(doc+"\n")

def crawl(feed, recurse=True):
  f = feedparser.parse(feed)
  if len(f.entries) == 0 and f.has_key('bozo_exception'):
    print 'bozo'
    with open('bozos', 'a') as output:
      output.write(feed+"\n")
    return

  feedinfo[feed] = deunicodify({'title': feedtitle(f), 'description': feeddesc(f), 'site': site(f), 'url': feed, 'author': author(f)})
  for item in reversed(f.entries):
    try:
      while os.path.exists('/tmp/pause_crawl'):
        time.sleep(300)

      if recurse:
        priorityCrawl()

      crawlUrl(item.link, {'title': title(item), 'feedtitle': f.feed.title, 'date': date(item), 'feeddate': time.mktime(time.gmtime()), 'feed': feed, 'site': site(f), 'description': desc(item)})
    except KeyboardInterrupt: raise
    except: traceback.print_exc(file=sys.stdout)

def priorityCrawl():
  while True:
    try: feed = priority_crawl.readline().rstrip()
    except IOError: break
    if not feed: break
    print 'priority crawl:', feed
    crawl(feed, recurse=False)

def deunicodify(hash):
  hash['unicode'] = ' '.join([normalize(val) for val in hash.values()])
  return hash

import unicodedata
def normalize(s):
  try:
    return ''.join([unicodedata.normalize('NFKD', c)[0] for c in s])
  except KeyboardInterrupt:
    raise
  except:
    return ''

def author(f):
  try: f.feed.author
  except KeyboardInterrupt:
    raise
  except:
    print '!auth'
    return ''

def feedtitle(f):
  try: return f.feed.title
  except KeyboardInterrupt:
    raise
  except:
    print '!ftit'
    return ''

def feeddesc(f):
  try: return f.feed.description
  except KeyboardInterrupt:
    raise
  except:
    print '!fdesc'
    return ''

def date(item):
  if not item.has_key('date'): return None
  return time.mktime(item.date_parsed) # XXX: is date_parsed UTC?

def site(f):
  try: return f.feed.link
  except KeyboardInterrupt: raise
  except: return None

def title(item):
  try: return item.title
  except KeyboardInterrupt: raise
  except: return None

def desc(item):
  if item.has_key('content'):
    return item['content'][0]['value']
  elif item.has_key('summary'):
    return item['summary']
  else:
    print '!desc'
    return ''

def main():
  print "---", time.asctime(time.localtime())
  try:
    i=0
    for feed in loadFeeds():
      try:
        print "-", feed
        crawl(feed)
      except KeyboardInterrupt: raise
      except: traceback.print_exc(file=sys.stdout)

      i += 1
      if i%10 == 0:
        print "saving feedinfo"
        saveFeedInfo('feedinfo.intermediate')
  finally:
    saveFeedInfo('feedinfo')
    saveUrlMap()

if __name__ == '__main__':
  loadUrlMap()
  backupFeedinfo()

  while True:
    main()
