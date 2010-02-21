import sys
from datetime import date

for i, arg in enumerate(sys.argv[1:]):
  print i, date.fromtimestamp(int(arg))
