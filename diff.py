from sys import argv

def slurp(f):
  return open(f).read()

if argv[1] == 'difflib':
  import difflib
  s = difflib.SequenceMatcher(a=slurp(argv[2]), b=slurp(argv[3]))
  print s.get_matching_blocks()

elif argv[1] == 'dmp':
  from diff_match_patch import diff_match_patch
  s = diff_match_patch()
  print [[x[0], len(x[1])] for x in s.diff_main(slurp(argv[2]), slurp(argv[3]))]
