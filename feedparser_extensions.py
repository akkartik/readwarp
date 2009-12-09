import feedparser
def sepTimezone(dateString):
  if dateString[-3] == ':':
    return dateString[:-6], dateString[-6:-3]+dateString[-2:]
  else:
    return dateString[:-5], dateString[-5:]

# http://stackoverflow.com/questions/526406/python-time-to-age-part-2-timezones
def getFuckingPythonToParseNumericTimezones(dateString, format):
  from datetime import timedelta, datetime
  dateString = dateString.strip()
  t, tz = sepTimezone(dateString)
  return datetime.timetuple(datetime.strptime(t, format)
                        + timedelta(hours=int(tz[0:2]), minutes=int(tz[3:])))

# http://www.aaronsw.com/weblog/index.xml
def sillyFormat1(dateString):
  try: return getFuckingPythonToParseNumericTimezones(dateString, "%B %d, %Y")
  except: traceback.print_exc(file=sys.stdout)
feedparser.registerDateHandler(sillyFormat1)
