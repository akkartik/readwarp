import sys, os, time, re, math, string, traceback, json
from BeautifulSoup import BeautifulSoup
import StringIO

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
  else:
    raise "blahblah"

def hint_contents(file):
  try:
    doc = (file.split('/')[-1])[:-4]
    mdata = json.load(open('urls/'+doc+'.metadata'))
    for item in json.load(open('urls/'+urlToFilename(mdata['feed'])+'.feed'))['entries']:
      if item['link'] == mdata['url']:
        try: return desc(item)
        except:
          print "ZZZZZZZZZZZ"
          print item
          print item.keys()
          traceback.print_exc(file=sys.stdout)
  except: return ''

# readability plugin
def cleanup(file, debug=False):
  contents = open(file).read()
  deschint = hint_contents(file)
  print deschint.__class__
  soup = BeautifulSoup(re.sub(r"<br\s*/?\s*>\s*<br\s*/?\s*>", "</p><p>", contents))
  allParagraphs = soup.findAll('p')

  contentLikelihood = {}
  for para in allParagraphs:
    parent = para.parent
    pars = str(parent)
    if not contentLikelihood.has_key(pars):
      contentLikelihood[pars] = init(parent)

    text = re.sub(r"<[^>]*>", "", para.renderContents())
    if len(text) > 40:
      contentLikelihood[pars] += math.log(len(re.sub(r"<[^>]*>", "", para.renderContents())))
    contentLikelihood[pars] += commaCount(para)

  for node in sortedKeys(contentLikelihood):
    if debug:
      print "==", contentLikelihood[node]
      print node
    if not deschint or deschint in node:
      return node

  return ''

def commaCount(node):
  return len(node.renderContents().split(','))

def cleanAll():
  for line in open("fifos/crawl").readlines():
    doc = line[:-1]
    print doc
    f = 'urls/'+doc+'.raw'
    f2 = 'urls/'+doc+'.clean'
    try:
      with open(f2, 'w') as output:
        output.write(cleanup(f))
      with open('fifos/clean', 'w') as fifo:
        fifo.write(line)
    except: traceback.print_exc(file=sys.stdout)

def testAll():
  dir='test/fixtures/htmlclean/correct'
  newLine=False
  numcorrect=numincorrect=0
  for file in os.listdir(dir):
    if file[-4:] == '.raw':
      f = dir+'/'+file
      f2 = dir+'/'+file[:-3]+'clean'
      try:
        expected = open(f2).read()
        got = cleanup(f)
        if expected != got:
          if newLine: print
          print "failed", file
          newLine=False
          numincorrect+=1
        else:
          sys.stdout.write('.')
          sys.stdout.flush()
          newLine=True
          numcorrect+=1
          continue
      except: traceback.print_exc(file=sys.stdout)

  if newLine: print
  print (numcorrect+numincorrect)
  if numincorrect > 0:
    print numincorrect, "failed"

def text(s):
  return re.sub(r"\s+", " ", re.sub(r"<[^>]*>", "", s))

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    if sys.argv[1] == 'test':
      testAll()
    elif os.path.exists(sys.argv[1]):
      cleanup(sys.argv[1], debug=True)
    elif os.path.exists('urls/'+sys.argv[1]+'.raw'):
      cleanup('urls/'+sys.argv[1]+'.raw', debug=True)
    elif os.path.exists('test/htmlclean/'+sys.argv[1]):
      cleanup('test/htmlclean/'+sys.argv[1], debug=True)
