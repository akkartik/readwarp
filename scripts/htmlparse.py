from sys import argv
from BeautifulSoup import BeautifulSoup
from utils import slurp

old = slurp(argv[1])
print BeautifulSoup(old)
