import sys
import htmlclean

if __name__ == '__main__':
  print htmlclean.fuzzycheck(open(sys.argv[1]).read(), open(sys.argv[2]).read(), True)
