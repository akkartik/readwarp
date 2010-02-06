import os, sys, re, traceback, time, pickle
import urlparse, urllib2, openanything
UrlOpener = urllib2.build_opener(openanything.SmartRedirectHandler())
import timeoutsocket
timeoutsocket.setDefaultSocketTimeout(20)

import feedparser, feedparser_extensions
from BeautifulSoup import BeautifulSoup
import json
from json_extensions import to_json

from utils import urlToFilename

canonical_url = {}
def loadUrlMap():
  global canonical_url
  if os.path.exists('snapshots/url_map'):
    with open('snapshots/url_map') as input:
      canonical_url = pickle.load(input)

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
def backupFeedinfo():
  try: shutil.copyfile('snapshots/feedinfo', 'snapshots/feedinfo.'+str(time.time()))
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
  return type == 'data' or type.find('text') > -1

def crawlUrl(rurl, metadata):
  soup = None
  url = None
  if canonical_url.has_key(rurl):
    url = canonical_url[rurl]
  else:
    try: url, contents = urlOpen(rurl)
    except timeoutsocket.Timeout: return

    canonical_url[rurl] = url

    soup = BeautifulSoup(contents)
    for node in soup.findAll(True):
      absolutify(node, 'href', url)
      absolutify(node, 'src', url)

  doc = urlToFilename(url)
  outfilename = 'urls/'+doc
  if soup and not os.path.exists(outfilename+'.raw'):
    print repr(url)
    with open(outfilename+'.raw', 'w') as output:
      output.write(soup.renderContents())

  if not goodFileType(outfilename+'.raw'):
    os.unlink(outfilename+'.raw')
    return

  if not os.path.exists(outfilename+'.metadata'):
    metadata['url'] = url
    try:
      with open(outfilename+'.metadata', 'w') as output:
        json.dump(metadata, output, default=to_json)
    except:
      traceback.print_exc(file=sys.stdout)
      try: os.unlink(outfilename+'.metadata')
      except os.OSError: pass

    with open('fifos/crawl', 'w') as fifo:
      fifo.write(doc+"\n")

def crawl(feed):
  f = feedparser.parse(feed)
  with open('urls/'+urlToFilename(feed)+'.feed', 'w') as output:
    json.dump([[g.link, title(g)] for g in f.entries], output, default=to_json)
  return
  if len(f.entries) == 0 and f.has_key('bozo_exception'):
    print 'bozo'
    return

  feedinfo[feed] = {'title': feedtitle(f), 'description': feeddesc(f), 'site': site(f), 'url': feed, 'author': author(f)}
  for item in f.entries:
    try:
      crawlUrl(item.link, {'title': title(item), 'feedtitle': f.feed.title, 'date': date(item), 'feeddate': time.mktime(time.gmtime()), 'feed': feed, 'site': site(f), 'description': desc(item)})
    except: traceback.print_exc(file=sys.stdout)

def author(f):
  try: f.feed.author
  except:
    print '!auth'
    return ''

def feedtitle(f):
  try: return f.feed.title
  except:
    print '!ftit'
    return ''

def feeddesc(f):
  try: return f.feed.description
  except:
    print '!fdesc'
    return ''

def date(item):
  if not item.has_key('date'): return None
  return time.mktime(item.date_parsed) # XXX: is date_parsed UTC?

def site(f):
  try: return f.feed.link
  except: return None

def title(item):
  try: return item.title
  except: return None

def desc(item):
  if item.has_key('content'):
    return item['content'][0]['value']
  elif item.has_key('summary'):
    return item['summary']
  else:
    print '!desc'
    return ''

if __name__ == '__main__':
  loadUrlMap()
  backupFeedinfo()

  try:
    i=0
    for feed in loadFeeds():
      try:
        print "-", feed
        crawl(feed)
      except: traceback.print_exc(file=sys.stdout)

      i += 1
      if i%10 == 0:
        print "saving feedinfo"
        saveFeedInfo('feedinfo.intermediate')
  finally:
    saveFeedInfo('feedinfo')
    saveUrlMap()
