import sys, os, string, traceback

if __name__ == '__main__':
  while True:
    for line in open("fifos/gc").readlines():
      doc = line.splitlines()[0]
      print doc
      try:
        os.unlink('urls/'+doc+'.raw')
        os.unlink('urls/'+doc+'.metadata')
        os.unlink('urls/'+doc+'.clean')
      except KeyboardInterrupt: raise
      except: traceback.print_exc(file=sys.stdout)
