import sys, codecs
from utils import slurp
from BeautifulSoup import BeautifulSoup

soup = BeautifulSoup(slurp(sys.argv[1]))
with codecs.open(sys.argv[1]+'2', 'w') as output:
  output.write(str(soup))
