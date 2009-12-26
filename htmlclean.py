import sys, os, time, re, math, string, traceback, json
from BeautifulSoup import BeautifulSoup
import StringIO
from utils import *

from diff_match_patch import diff_match_patch

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

def fuzzymatch(a, b, debug=False):
  if isa(a, 'str'): a = unicode(a, errors='ignore')
  if isa(b, 'str'): b = unicode(b, errors='ignore')
  s = diff_match_patch()
  commons = [x[1] for x in s.diff_main(a, b) if x[0] == 0]
  if debug: print commons
  return float(sum([len(x) for x in commons]) - len(commons))/len(b) > 0.8

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
  contents = open(file).read()
  deschint = hint_contents(file)
  if debug:
    print "== deschint"
    print deschint
  soup = BeautifulSoup(re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "<p>", contents))

  if debug: print "== Phase 1"
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
  try: top_candidate_without_match = candidates[0]
  except: top_candidate_without_match = ''

  if debug: print "== Phase 2"
  scores = {}
  candidates = soup.findAll(True)
  print "phase 2", len(candidates)
  for i, node in enumerate(candidates):
    if i > 0 and i % 100 == 0: print " ", i
    l = txtlen(str(node))
    if l > 1:
      scores[str(node)] = score(node)/math.log(l)

  candidates = sortedKeys(scores)
  pick = pickTopMatchingCandidate(candidates, scores, deschint, debug)
  if pick: return pick

  return top_candidate_without_match

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
    f = 'urls/'+doc+'.raw'
    f2 = 'urls/'+doc+'.clean'
    try:
      with open(f2, 'w') as output:
        output.write(cleanup(f))
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
  if debug: print passed, match, dilution
  if dilution > 1.5:
    print expected
    print "==="
    print got
    os._exit(0)
  return passed

def test(f, debug=False):
  f2 = f[:-3]+'clean'
  expected = open(f2).read()
  got = cleanup(f, debug)
  passed = fuzzycheck(expected, got, debug)

  if not passed:
    with open(f2+'.error', 'w') as output:
      output.write(got)
  else:
    try: os.unlink(f2+'.error')
    except OSError: pass
  return passed

def testAll():
  dir='test/fixtures/clean'
  newLine=False
  numcorrect=numincorrect=0
  for file in os.listdir(dir):
    if file[-4:] == '.raw':
      if not test(dir+'/'+file):
        print "failed", file[:-4]
        numincorrect+=1
      else:
        print "passed", file[:-4]
        numcorrect+=1
      sys.stdout.flush()
  print numcorrect+numincorrect
  print numincorrect, "failed"

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    if sys.argv[1] == 'test':
      if len(sys.argv) == 2:
        testAll()
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
