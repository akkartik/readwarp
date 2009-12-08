import os, sys, re, traceback, time, pickle
import urlparse, urllib2, openanything
UrlOpener = urllib2.build_opener(openanything.SmartRedirectHandler())
import timeoutsocket
timeoutsocket.setDefaultSocketTimeout(20)

import feedparser, json
from BeautifulSoup import BeautifulSoup

canonical_url = {}
def loadUrlMap():
  global canonical_url
  if os.path.exists("snapshot.url_map"):
    with open("snapshot.url_map") as input:
      canonical_url = pickle.load(input)

def saveUrlMap():
  if len(canonical_url) > 0:
    with open("snapshot.url_map", 'w') as output:
      pickle.dump(canonical_url, output)

def loadFeeds():
  ans = set()
  with open('feeds') as input:
    for line in input:
      yield line.rstrip()

def urlToFilename(url):
  return re.sub(r'[^a-zA-Z0-9]', '_', url)

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
  try: f = UrlOpener.open(request)
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
  print 'file:', type
  return type == 'data' or type.find('text') > -1

def crawlUrl(rurl, metadata):
  soup = None
  url = None
  if canonical_url.has_key(rurl):
    print rurl, 'present'
    url = canonical_url[rurl]
  else:
    try: url, contents = urlOpen(rurl)
    except timeoutsocket.Timeout: return

    canonical_url[rurl] = url

    soup = BeautifulSoup(contents)
    for node in soup.findAll(True):
      absolutify(node, 'href', url)
      absolutify(node, 'src', url)

  print url
  doc = urlToFilename(url)
  outfilename = 'urls/'+doc
  if soup and not os.path.exists(outfilename+'.raw'):
    with open(outfilename+'.raw', 'w') as output:
      output.write(soup.renderContents())

  if not goodFileType(outfilename+'.raw'):
    os.unlink(outfilename+'.raw')
    return

  if not os.path.exists(outfilename+'.metadata'):
    metadata['url'] = url
    try:
      with open(outfilename+'.metadata', 'w') as output:
        json.dump(metadata, output)
    except:
      traceback.print_exc(file=sys.stdout)
      try: os.unlink(outfilename+'.metadata')
      except os.OSError: pass

  with open('fifos/crawl', 'w') as output:
    output.write(doc+"\n")

def crawl(feed):
  f = feedparser.parse(feed)
  for item in f.entries:
    try:
      print repr(item.title)
      crawlUrl(item.link, {'title': item.title, 'feedtitle': f.feed.title, 'date': date(item), 'feeddate': time.mktime(time.gmtime()), 'feed': feed, 'site': f.feed.link})
    except: traceback.print_exc(file=sys.stdout)

def date(item):
  if not item.has_key('date'): return None
  return time.mktime(item.date_parsed) # XXX: is date_parsed UTC?

if __name__ == '__main__':
  loadUrlMap()

  try:
    for feed in loadFeeds():
      try:
        print "-", feed
        crawl(feed)
        break
      except: traceback.print_exc(file=sys.stdout)
  finally:
    saveUrlMap()
