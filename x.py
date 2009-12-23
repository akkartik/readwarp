import difflib

c0 = open("x0").read()
c1 = open("x1").read()

s= difflib.SequenceMatcher(a=c0, b=c1)
print s.get_matching_blocks()
