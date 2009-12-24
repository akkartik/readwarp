import sys, os, time, re, math, string, traceback, json
from BeautifulSoup import BeautifulSoup
import StringIO

#? import difflib
from diff_match_patch import diff_match_patch

def sortedKeys(h):
  l = h.keys()
  l.sort(cmp=lambda x,y: -cmp(h[x], h[y]))
  return l

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
  text = re.sub(r"<[^>]*>", "", node.renderContents())
  if len(text) > 10:
    ans += math.log(len(text))
  ans += commaCount(node)
  return ans
 
def urlToFilename(url):
  return re.sub(r'[^a-zA-Z0-9]', '_', url)

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

#? def matching_size(a, b, debug):
#?   s = difflib.SequenceMatcher(a=a, b=b)
#?   lens = [x[2] for x in s.get_matching_blocks()]
#?   if debug:
#?     print "=="
#?     print b
#?     print sum(lens), len(b), s.get_matching_blocks()
#?     for x,y,z in s.get_matching_blocks():
#?       print a[x:x+z]
#?   return sum(lens)

#? def fuzzymatch(a, b, debug=False):
#?   print min(len(a), len(b))
#?   return (float(max(matching_size(a,b,debug), matching_size(b,a,debug))) /
#?             min(len(a), len(b))) > 0.8

def isa(var, type):
  return var.__class__.__name__ == type

def fuzzymatch(a, b, debug=False):
  if isa(a, 'str'): a = unicode(a, errors='ignore')
  if isa(b, 'str'): b = unicode(b, errors='ignore')
  s = diff_match_patch()
  dr = min(len(a), len(b))
  commons = [x[1] for x in s.diff_main(a, b) if x[0] == 0]
  if debug: print commons
  return float(sum([len(x) for x in commons]) - len(commons))/dr > 0.8

def pickTopMatchingCandidate(candidates, scores, hint, debug):
  if debug: print "==", len(candidates), "candidates"

  for node in candidates:
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
  soup = BeautifulSoup(re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "</p><p>", contents))
  allParagraphs = soup.findAll('p')

  if debug: print "== Phase 1"
  contentLikelihood = {}
  for para in allParagraphs:
    parent = para.parent
    pars = str(parent)
#?     pars = unicode(pars, errors='ignore')
    if not contentLikelihood.has_key(pars):
      contentLikelihood[pars] = init(parent)

    text = re.sub(r"<[^>]*>", "", para.renderContents())
    if len(text) > 40:
      contentLikelihood[pars] += math.log(len(re.sub(r"<[^>]*>", "", para.renderContents())))
    contentLikelihood[pars] += commaCount(para)

  candidates = sortedKeys(contentLikelihood)
  pick = pickTopMatchingCandidate(candidates, contentLikelihood, deschint, debug)
  if pick: return pick
  try: top_candidate_without_match = candidates[0]
  except: top_candidate_without_match = ''

  if debug: print "== Phase 2"
  contentLikelihood = {}
  for node in soup.findAll(True):
    s = str(node)
    if not contentLikelihood.has_key(s):
      contentLikelihood[s] = init(node)

    text = re.sub(r"<[^>]*>", "", node.renderContents())
    if len(text) > 40:
      contentLikelihood[s] += math.log(len(re.sub(r"<[^>]*>", "", node.renderContents())))
    contentLikelihood[s] += commaCount(node)

  candidates = sortedKeys(contentLikelihood)
  pick = pickTopMatchingCandidate(candidates, contentLikelihood, deschint, debug)
  if pick: return pick

  return top_candidate_without_match

def commaCount(node):
  return len(node.renderContents().split(','))

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

def test(f, debug=False):
  f2 = f[:-3]+'clean'
  expected = open(f2).read()
  got = cleanup(f, debug)
#?   print "==="
#?   print got
  match = fuzzymatch(got, expected, debug)
  dilution = float(len(expected))/len(got)
  passed = (match and dilution > 0.6)
  if debug: print passed, match, dilution
  if not passed:
    print match, dilution
    with open(f2+'.error', 'w') as output:
      output.write(got)
  else:
    try: os.unlink(f2+'.error')
    except OSError: pass
  return passed

def testAll():
  dir='test/fixtures/htmlclean/correct'
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

def text(s):
  return re.sub(r"\s+", " ", re.sub(r"<[^>]*>", "", s))

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    if sys.argv[1] == 'test':
      if len(sys.argv) == 2:
        testAll()
      elif os.path.exists('test/fixtures/htmlclean/correct/'+sys.argv[2]):
        test('test/fixtures/htmlclean/correct/'+sys.argv[2], debug=True)
      elif os.path.exists('test/fixtures/htmlclean/correct/'+sys.argv[2]+'.raw'):
        test('test/fixtures/htmlclean/correct/'+sys.argv[2]+'.raw', debug=True)
    elif os.path.exists(sys.argv[1]):
      cleanup(sys.argv[1], debug=True)
    elif os.path.exists('urls/'+sys.argv[1]+'.raw'):
      cleanup('urls/'+sys.argv[1]+'.raw', debug=True)
    elif os.path.exists('test/fixtures/htmlclean/correct/'+sys.argv[1]):
      cleanup('test/fixtures/htmlclean/correct/'+sys.argv[1], debug=True)
