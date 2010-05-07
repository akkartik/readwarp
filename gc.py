import sys, os, string, traceback

if __name__ == '__main__':
  while True:
    for line in open("fifos/gc").readlines():
      doc = line[:-1]
      print doc
      try:
        pass
      except: traceback.print_exc(file=sys.stdout)
