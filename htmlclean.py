import sys, os, time, re, math, string, traceback, json, codecs
from BeautifulSoup import BeautifulSoup, Tag, NavigableString
from utils import *
import difflib

# http://code.google.com/p/arc90labs-readability/source/browse/tags/final-releases/0.4.5/js/readability.js

def cleanup(file):
  deschint = hint_contents(file)
  soup = preproc(file)

  scores = {}
  for para in soup.findAll('p'):
    parent = para.parent
    pars = unicode(parent)
    if not scores.has_key(pars):
      scores[pars] = init(parent)

    scores[pars] += lenScore(para)
    scores[pars] += commaCount(para)

  candidates = sortedKeys(scores)
  pick = pickTopMatchingCandidate(candidates, scores, htmlstrip(deschint))
  if pick: return postproc(pick)

  if deschint == '':
    try: return postproc(candidates[0])
    except: pass
  return deschint

badParaRegex = re.compile("comment|meta|footer|footnote", re.I)
goodParaRegex = re.compile("^(post|hentry|entry[-]?(content|text|body)?|article[-]?(content|text|body)?)$", re.I)
def init(node):
  ans = 0
  if node.has_key('class'):
    if badParaRegex.search(node['class']):
      ans = ans - 50
    if goodParaRegex.search(node['class']):
      ans = ans + 25

  if node.has_key('id'):
    if badParaRegex.search(node['id']):
      ans = ans - 50
    if goodParaRegex.search(node['id']):
      ans = ans + 25

  return ans

def score(node):
  ans = init(node)
  ans += lenScore(node)
  ans += commaCount(node)
  return ans

def desc(item):
  if item.has_key('content'):
    return item['content'][0]['value']
  elif item.has_key('summary'):
    return item['summary']
  elif item.has_key('description'):
    return item['description']
  else:
    raise "blahblah"

def hint_contents(file):
  try:
    mdata = json.load(open(file[:-4]+'.metadata'))
    if mdata.has_key('description'): return mdata['description']

    for item in json.load(open('urls/'+urlToFilename(mdata['feed'])+'.feed'))['entries']:
      if item['link'] == mdata['url']:
        try: return desc(item)
        except:
          print item
          print item.keys()
          traceback.print_exc(file=sys.stdout)
          raise
  except: pass
  return ''

def matching_size(a, b):
  s = difflib.SequenceMatcher(a=a, b=b)
  lens = [x[2] for x in s.get_matching_blocks()]
  return sum(lens)

def fuzzymatch(a, b):
  if a == '' or b == '': return False
  return (float(max(matching_size(a,b), matching_size(b,a))) /
            min(len(a), len(b))) > 0.8

def pickTopMatchingCandidate(candidates, scores, hint_stripped):
  for i, node in enumerate(candidates):
    if i > 0 and i % 100 == 0: print "  ", i
    if hint_stripped == '' or fuzzymatch(htmlstrip(node), hint_stripped):
      return node

  return None

def preproc(file):
  soup = BeautifulSoup(re.sub(r'</?font[^>]*>', '',
    re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "<p>", slurp(file))))

  for s in soup.findAll('script'): s.extract()
  for s in soup.findAll('style'): s.extract()
  for s in soup.findAll('link', attrs={'type': 'text/css'}): s.extract()

  for s in soup.findAll('form'): s.extract()
  for s in soup.findAll('object'): s.extract()
  for s in soup.findAll('iframe'): s.extract()

  for s in soup.findAll('h1'): s.extract()
  if len(soup.findAll('h2')) == 1:
    for s in soup.findAll('h2'): s.extract()

  for s in soup.findAll(True):
    try: del(s['style'])
    except KeyError: pass

  return soup

def postproc(node):
  if node is None: return
  return re.sub(r"^<td ", "<div ", node)

def commaCount(node):
  return len(node.renderContents().split(','))

def htmlstrip(s):
  return re.sub(r"<[^>]*>", "", s)

def lenScore(node):
  text = htmlstrip(node.renderContents())
  if len(text) > 40:
    return math.log(len(text))
  return 0

def cleanAll():
  for line in open("fifos/crawl").readlines():
    doc = line[:-1]
    print doc
    f = 'urls/'+doc+'.raw'
    f2 = 'urls/'+doc+'.clean'
    try:
      with codecs.open(f2, 'w', 'utf-8') as output:
        output.write(cleanup(f))
      with open('fifos/clean', 'w') as fifo:
        fifo.write(line)
      with open('docs', 'a+') as fifo:
        fifo.write(line)
    except: traceback.print_exc(file=sys.stdout)

def txtlen(html):
  return len(htmlstrip(html))

def fuzzycheck(expected, got):
  match = fuzzymatch(got, expected)
  if not match: return False

  dilution = float(len(expected))/len(got)
  passed = dilution > 0.6
  if match and dilution > 0.5:
    print match, dilution
  return passed

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    with codecs.open(sys.argv[1]+'.clean', 'w', 'utf-8') as output:
      output.write(cleanup(sys.argv[1]))
