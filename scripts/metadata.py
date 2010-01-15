import os, sys, re, traceback, time, pickle
import json

file=sys.argv[1]
var=sys.argv[2]

mdata=json.load(open(file))
print mdata[var]
