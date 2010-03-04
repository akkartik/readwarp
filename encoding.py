# http://www.pyzine.com/Issue008/Section_Articles/article_Encodings.html
# adapted from io.py
# in the docutils extension module
# see http://docutils.sourceforge.net

import locale
def guess_encoding(data):
    """
    Given a byte string, attempt to decode it.
    Tries the standard 'UTF8' and 'latin-1' encodings,
    Plus several gathered from locale information.

    The calling program *must* first call 
        locale.setlocale(locale.LC_ALL, '')

    If successful it returns 
        (decoded_unicode, successful_encoding)
    If unsuccessful it raises a ``UnicodeError``
    """
    successful_encoding = None
    # we make 'utf-8' the first encoding
    encodings = ['utf-8']
    #
    # next we add anything we can learn from the locale
    try:
        encodings.append(locale.nl_langinfo(locale.CODESET))
    except AttributeError:
        pass
    try:
        encodings.append(locale.getlocale()[1])
    except (AttributeError, IndexError):
        pass
    try:
        encodings.append(locale.getdefaultlocale()[1])
    except (AttributeError, IndexError):
        pass
    #
    # we try 'latin-1' last
    encodings.append('latin-1')
    for enc in encodings:
        # some of the locale calls 
        # may have returned None
        if not enc:
            continue
        try:
            decoded = unicode(data, enc)
            successful_encoding = enc

        except (UnicodeError, LookupError):
            pass
        else:
            break
    if not successful_encoding:
         raise UnicodeError(
        'Unable to decode input data.  Tried the following encodings: %s.'
        % ', '.join([repr(enc) for enc in encodings if enc]))
    else:
         return (decoded, successful_encoding)

# uses the guess_encoding function from above
import codecs
import sys

bomdict = { #codecs.BOM_UTF7 : 'UTF7', 
            codecs.BOM_UTF8 : 'UTF8', 
            codecs.BOM_UTF16_BE : 'UTF-16BE', 
            codecs.BOM_UTF16_LE : 'UTF-16LE' }

def to_byte_string(the_text):
  locale.setlocale(locale.LC_ALL, '')     # set the locale
  # check if there is Unicode signature
  for bom, encoding in bomdict.items():   
      if the_text.startswith(bom):
          the_text = the_text[len(bom):]
          break
  else:
     bom  = None
     encoding = None

  if encoding is None:    # there was no BOM
      try:
          unicode_text, encoding = guess_encoding(the_text)
      except UnicodeError:
          print "Sorry - we can't work out the encoding."
          raise
  else:                   
      # we found a BOM so we know the encoding
      unicode_text = the_text.decode(encoding)
  # now you have your Unicode text.. and can do with it what you will

  # now we want to re-encode it to a byte string
  # so that we can write it back out
  # we will reuse the original encoding, and preserve any BOM
  if bom is not None:
      if encoding.startswith('UTF-16'):       
      # we will use the right 'endian-ness' for this machine
           encoding = 'UTF-16'
           bom = codecs.BOM_UTF16
  byte_string = unicode_text.encode(encoding)
  if bom is not None:
      byte_string = bom + byte_string
  # now we have the text encoded as a byte string, ready to be saved to a file
  return byte_string
