import sys, os, time, re, math, string, traceback, codecs
from BeautifulSoup import BeautifulSoup, Tag, NavigableString
from utils import *

# http://arc90labs-readability.googlecode.com/svn/tags/final-releases/1.5.0/js/readability.js
# Except rendering stuff, getting article title, managing multiple frames, killing extra breaks,
# whitespace

unlikelyCandidateRegex = 'combx|comment|disqus|foot|header|menu|meta|rss|shoutbox|sidebar|sponsor'
maybeCandidateRegex = 'and|article|body|column|main'
positiveClassRegex = 'article|body|content|entry|hentry|page|pagination|post|text'
negativeClassRegex = 'combx|comment|contact|foot|footer|footnote|link|media|meta|promo|related|scroll|shoutbox|sponsor|tags|widget'
divToPElementsRegex = '<(a|blockquote|dl|div|img|ol|p|pre|table|ul)'
videoRegex = 'http:\/\/(www\.)?(youtube|vimeo)\.com'

whitespaceTrimRegex = '^\s+|\s+$'
replaceBrsRegex = '(<br[^>]*>[ \n\r\t]*){2,}'
replaceFontsRegex = '<(\/?)font[^>]*>'
normalizeRegex = '\s{2,}'
killBreaksRegex = '(<br\s*\/?>(\s|&nbsp;?)*){1,}'

def cleanup(file):
  article = grabArticle(file, weight_classes=True, strip_unlikelys=True)
  if len(getInnerText(article, False)) < 500:
    article = grabArticle(file, weight_classes=True, strip_unlikelys=False)
  if len(getInnerText(article, False)) < 500:
    article = grabArticle(file, weight_classes=False, strip_unlikelys=False)

  return article

def preproc(file):
  soup = BeautifulSoup(re.sub(replaceFontsRegex, '<\\1span>',
    re.sub(replaceBrsRegex, "</p><p>", slurp(file))))

  for s in soup.findAll('script'): s.extract()
  for s in soup.findAll('style'): s.extract()
  for s in soup.findAll('link', attrs={'type': 'text/css'}): s.extract()

  return soup

def postproc(soup):
  for s in soup.findAll(True):
    try:
      if not re.match(re.compile('display:\s*none'), s['style']):
        del(s['style'])
    except KeyError: pass

  for s in soup.findAll('form'): s.extract()
  for s in soup.findAll('object'):
    done = False
    for attr, val in s.attrs:
      if re.search(videoRegex, val, re.IGNORECASE):
        done = True
        break
    if not done and not re.search(videoRegex, s.renderContents(), re.IGNORECASE):
      s.extract()

  for s in soup.findAll('h1'): s.extract()
  if len(soup.findAll('h2')) == 1:
    for s in soup.findAll('h2'): s.extract()
  for s in soup.findAll('iframe'): s.extract()

  cleanHeaders(soup)
  cleanConditionally(soup, "table")
  cleanConditionally(soup, "ul")
  cleanConditionally(soup, "div")

#?   for s in soup.findAll('textarea'): s.extract()

#?   for s in soup.findAll('table'):
#?     try: del(s['width'])
#?     except KeyError: pass

  return soup.renderContents()

def init(node, weight_classes):
  ans = 0
  tag = string.lower(node.name)
  if tag == 'div': ans = ans + 5
  elif find(tag, ['pre', 'td', 'blockquote']): ans = ans + 3
  elif find(tag, ['address', 'ol', 'ul', 'dl', 'dd', 'dt', 'li', 'form']): ans = ans - 3
  elif find(tag, ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'th']): ans = ans - 5

  if weight_classes:
    return ans + getClassWeight(node)
  else:
    return ans

scores = {}
def grabArticle(file, weight_classes, strip_unlikelys):
  global scores
  scores = {}
  soup = preproc(file)

  for node in soup.findAll('*'):
    if strip_unlikelys:
      if (string.lower(node.name) != 'body'
          and re.search(unlikelyCandidateRegex, node['class'], re.IGNORECASE)
          and not re.search(maybeCandidateRegex.search, node['class'], re.IGNORECASE)):
        node.extract()
        continue

      if node.name == 'div':
        if not re.search(divToPElementsRegex, node.renderContents(), re.IGNORECASE):
          node.name = 'p'
        else:
          for n in node.contents:
            if isa(n, 'NavigableString'):
              newNode = Tag(soup, 'p', attrs={'style': 'display:inline'})
              n.replaceWith(newNode)
              newNode.insert(0, n)

  for para in soup.findAll('p'):
    parent = para.parent
    grandparent = parent.parent
    innerText = getInnerText(para)

    if len(innerText) < 25: continue

    pars = getInnerText(parent)
    if not scores.has_key(pars):
      scores[pars] = [init(parent, weight_classes), parent]
    grandpars = getInnerText(parent)
    if not scores.has_key(grandpars):
      scores[grandpars] = [init(grandparent, weight_classes), grandparent]

    score = 1 + commaCount(para) + min([math.floor(len(innerText)/100), 3])
    scores[pars][0] += score
    scores[grandpars][0] += score

  topCandidateS = None
  for pars in scores.keys():
    if not topCandidateS or scores[pars][0] > scores[topCandidateS][0]:
      topCandidateS = pars

  topCandidate = scores[topCandidateS][1]
  result = Tag(soup, 'div')
  siblingScoreThreshold = max([10, scores[topCandidateS][0]*0.2])
  for siblingNode in topCandidate.parent.contents:
    siblingS = getInnerText(siblingNode)
    append = False
    if siblingNode == topCandidate:
      append = True
    elif scores.has_key(siblingS) and scores[siblingS] > siblingScoreThreshold:
      append = True
    elif isa(siblingNode, 'Tag') and siblingNode.name == 'p':
      linkDensity = getLinkDensity(siblingNode)
      nodeContent = getInnerText(siblingNode)
      nodeLength = len(nodeContent)
      if nodeLength > 80 and linkDensity > 0.25:
        append = True
      elif nodeLength < 80 and linkDensity == 0 and re.search(r'\.( |$)', nodeContent):
        append = True

    if append:
      if isa(siblingNode, 'Tag') and not find(siblingNode.name, ['p', 'div']):
        siblingNode.name = 'div'
      result.append(siblingNode)

  return postproc(scores[topCandidateS][1])

def getInnerText(node, normalizeSpaces=True):
  result = re.sub(whitespaceTrimRegex, "", unicode(node), re.UNICODE)
  if normalizeSpaces:
    result = re.sub(normalizeRegex, " ", result, re.UNICODE)
  return result

def commaCount(node):
  return len(node.renderContents().split(','))

def getLinkDensity(node):
  return sum([len(s) for s in node.findAll('a')]) / len(getInnerText(node))

def getClassWeight(node):
  weight = 0
  try:
    if re.search(negativeClassRegex, node['class'], re.IGNORECASE):
      weight = weight - 25
    if re.search(positiveClassRegex, node['class'], re.IGNORECASE):
      weight = weight + 25
  except KeyError: pass

  try:
    if re.search(negativeClassRegex, node['id'], re.IGNORECASE):
      weight = weight - 25
    if re.search(positiveClassRegex, node['id'], re.IGNORECASE):
      weight = weight + 25
  except KeyError: pass

  return weight

def cleanConditionally(soup, tag):
  for node in soup.findAll(tag):
    weight = getClassWeight(node)
    try: contentScore = scores[getInnerText(node)]
    except KeyError: contentScore = 0
    if weight+contentScore < 0:
      node.extract()
      return

    if commaCount(node) < 10:
      p = len(node.findAll('p'))
      img = len(node.findAll('img'))
      li = len(node.findAll('li'))
      input = len(node.findAll('input'))
      embedCount = len(filter(lambda(x): not re.search(videoRegex, x['src'], re.IGNORECASE),
                              node.findAll('embed')))

      linkDensity = getLinkDensity(node)
      contentLength = len(getInnerText(node))

      if (img > p
          or (li > p and not find(tag, ['ul', 'ol']))
          or (input > math.floor(p/3))
          or (contentLength < 25 and not find(img, [1, 2]))
          or (weight < 25 and linkDensity > 0.2)
          or (weight >= 25 and linkDensity > 0.5)
          or (embedCount == 1 and contentLength < 75)
          or (embedCount > 1)):
        node.extract()

def cleanHeaders(soup):
  for headerIndex in range(1, 8):
    for node in soup.findAll('h'+str(headerIndex)):
      if getClassWeight(node) < 0 or getLinkDensity(node) > 0.33:
        node.extract()

def find(elem, l):
  l.count(elem)

def desirableVideo(node):
  return not re.search(videoRegex, node['src'], re.IGNORECASE)

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

if __name__ == '__main__':
  if len(sys.argv) == 1:
    while True:
      cleanAll()
  else:
    with codecs.open(sys.argv[1]+'.clean', 'w', 'utf-8') as output:
      output.write(cleanup(sys.argv[1]))
