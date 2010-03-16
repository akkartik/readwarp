import sys
from datetime import datetime

for i, arg in enumerate(sys.argv[1:]):
  print i, datetime.fromtimestamp(int(arg))
