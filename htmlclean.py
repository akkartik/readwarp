import sys, os, time, re, math, string, traceback, json
from BeautifulSoup import BeautifulSoup
import StringIO
import difflib
from utils import *

badParaRegex = re.compile("comment|meta|footer|footnote")
goodParaRegex = re.compile("^(post|hentry|entry[-]?(content|text|body)?|article[-]?(content|text|body)?)$")
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

def matching_size(a, b, debug):
  s = difflib.SequenceMatcher(a=a, b=b)
  lens = [x[2] for x in s.get_matching_blocks()]
  if debug:
    print "=="
    print b
    print sum(lens), len(b), s.get_matching_blocks()
  return sum(lens)

def fuzzymatch(a, b, debug=False):
  print min(len(a), len(b))
  if a == '' or b == '': return False
  return (float(max(matching_size(a,b,debug), matching_size(b,a,debug))) /
            min(len(a), len(b))) > 0.8

def pickTopMatchingCandidate(candidates, scores, hint, debug):
  if debug: print "==", len(candidates), "candidates"

  for i, node in enumerate(candidates):
    if i > 0 and i % 100 == 0: print "  ", i
    if debug:
      print "==", scores[node]
      print node
      print "=="
      print hint
    if hint == '' or fuzzymatch(node, hint):
      return node

  return None

def cleanup(file, debug=False):
  deschint = hint_contents(file)
  if debug:
    print "== deschint"
    print deschint
  soup = BeautifulSoup(re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "<p>", slurp(file)))

  for s in soup.findAll('script'): s.extract()
  for s in soup.findAll('style'): s.extract()
  for s in soup.findAll('link', attrs={'type': 'text/css'}): s.extract()
  for s in soup.findAll('form'): s.extract()

  scores = {}
  for para in soup.findAll('p'):
    parent = para.parent
    pars = str(parent)
    if not scores.has_key(pars):
      scores[pars] = init(parent)

    scores[pars] += lenScore(para)
    scores[pars] += commaCount(para)

  candidates = sortedKeys(scores)
  pick = pickTopMatchingCandidate(candidates, scores, deschint, debug)
  if pick: return pick

  if deschint == '': return candidates[0]
  return deschint

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
      with open(f2, 'w') as output:
        output.write(cleanup(f).encode('utf-8'))
      with open('fifos/clean', 'w') as fifo:
        fifo.write(line)
    except: traceback.print_exc(file=sys.stdout)

def txtlen(html):
  return len(htmlstrip(html))

def fuzzycheck(expected, got, debug=False):
  match = fuzzymatch(got, expected, debug)
  if not match: return False

  dilution = float(len(expected))/len(got)
  passed = dilution > 0.6
  if match and dilution > 0.5:
    print match, dilution
  if debug:
    print passed, match, dilution
    if dilution > 1.5:
      print expected
      print "==="
      print got
  return passed

numreallypassed=0
def test(f, debug=False):
  global numreallypassed
  f2 = f[:-3]+'clean'
  expected = slurp(f2)
  got = cleanup(f)
  if expected == got:
    passed = True
    numreallypassed += 1
  else:
    passed = fuzzycheck(expected, got)

  if debug: print passed
#?   if not passed:
#?     with open(f2+'.error', 'w') as output:
#?       output.write(got.encode('utf-8'))
#?   else:
#?     try: os.unlink(f2+'.error')
#?     except OSError: pass
  return passed

def scan(f):
  soup = BeautifulSoup(re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "<p>", slurp(f)))
  print '====', f
  for elem in soup.findAll(text=re.compile('comments')):
    print '=='
    print elem
  for elem in soup.findAll(text=re.compile('responses', re.I)):
    print '=='
    print elem

def testAll():
  dir='test/fixtures/clean'
  newLine=False
  numcorrect=numincorrect=0
  for file in os.listdir(dir):
    if file[-4:] == '.raw':
      scan(dir+'/'+file)
      if not test(dir+'/'+file):
        print "failed", file[:-4]
        numincorrect+=1
      else:
        print "passed", file[:-4]
        numcorrect+=1
      sys.stdout.flush()
  print numcorrect+numincorrect
  print numincorrect, "failed"
  print numreallypassed, "surely passed"

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    if sys.argv[1] == 'test':
      if len(sys.argv) == 2:
        testAll()
      elif os.path.exists(sys.argv[2]):
        cleanup(sys.argv[2], debug=True)
      elif os.path.exists('test/fixtures/clean/'+sys.argv[2]):
        test('test/fixtures/clean/'+sys.argv[2], debug=True)
      elif os.path.exists('test/fixtures/clean/'+sys.argv[2]+'.raw'):
        test('test/fixtures/clean/'+sys.argv[2]+'.raw', debug=True)
    elif os.path.exists(sys.argv[1]):
      cleanup(sys.argv[1], debug=True)
    elif os.path.exists('urls/'+sys.argv[1]+'.raw'):
      cleanup('urls/'+sys.argv[1]+'.raw', debug=True)
    elif os.path.exists('test/fixtures/clean/'+sys.argv[1]):
      cleanup('test/fixtures/clean/'+sys.argv[1], debug=True)
