from diff_match_patch import diff_match_patch

c0 = open("x0").read()
c1 = open("x1").read()

s = diff_match_patch()
for x, y in s.diff_main(c0, c1):
  if x == 0: print y

def fuzzymatch(a, b):
  s = diff_match_patch()
  dr = min(len(a), len(b))
  commons = [x[1] for x in s.diff_main(a, b) if x[0] == 0]
  return float(sum([len(x) for x in commons]) - len(commons))/dr

print fuzzymatch(c0, c1)
#? print fuzzymatch("This function is similar to diff_cleanupSemantic, except that instead of optimising a diff to be human-readable, it optimises the diff to be efficient for machine processing. The results of both cleanup types are often the same. ", "Given a diff, measure its Levenshtein distance in terms of the number of inserted, deleted or substituted characters. The minimum distance is 0 which means equality, the maximum distance is the length of the longer string. ")

#? import difflib
#? s= difflib.SequenceMatcher(a=c0, b=c1)
#? print s.get_matching_blocks()
