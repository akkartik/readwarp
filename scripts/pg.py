import sys
from datetime import datetime
import string

for line in sys.stdin.readlines():
  doc, mon, yr = string.split(line)
  print doc, datetime.strptime(mon+" "+yr, "%B %Y")
