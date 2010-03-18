import sys, string
import time
from datetime import datetime
import json
from json_extensions import to_json

for line in sys.stdin.readlines():
  doc, mon, yr = string.split(line)
  with open('urls/'+doc+'.metadata') as input:
    f = json.load(input)
  f['date'] = time.mktime(datetime.strptime(mon+" "+yr, "%B %Y").timetuple())
  with open(doc+'.metadata', 'w') as output:
    json.dump(f, output, default=to_json)
