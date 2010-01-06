import os
import json
from json_extensions import to_json

feeds = [line.strip() for line in open('feeds/All').readlines()]

replacements = {
  'http://scripting.com/rss.xml': 'http://www.scripting.com/rss.xml',
  'http://www.sethmohta.com/vinay/blog/?feed=rss2': 'http://www.vinaysethmohta.com/blog/feed/',
}

for file in os.listdir('urls'):
  if file[-9:] != '.metadata': continue

  mdata = json.load(open('urls/'+file))
  if mdata['feed'] in feeds: continue

  if mdata['feed']+'/' in feeds:
    print '/ ', file
    mdata['feed'] += '/'

  elif replacements.has_key(mdata['feed']):
    print 'R ', file
    mdata['feed'] = replacements[mdata['feed']]

  else:
    print 'R ', file
    continue

  try:
    with open('urls/'+file+'.new', 'w') as output:
      json.dump(mdata, output, default=to_json)
    os.rename('urls/'+file+'.new', 'urls/'+file)
  except: traceback.print_exc(file=sys.stdout)
