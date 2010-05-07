import sys, os, string, traceback

if __name__ == '__main__':
  while True:
    for line in open("fifos/gc").readlines():
      if line[:-1] == '\n':
        doc = line[:-1]
      else:
        doc = line
      print doc
      try:
        os.unlink('urls/'+doc+'.raw')
        os.unlink('urls/'+doc+'.metadata')
        os.unlink('urls/'+doc+'.clean')
      except: traceback.print_exc(file=sys.stdout)
