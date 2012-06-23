#!/usr/bin/env python

import sys, os
if 'PYGMENTS_PATH' in os.environ:
  sys.path.insert(0, os.environ['PYGMENTS_PATH'])

import pygments
import pygments.lexers, pygments.formatters, pygments.styles, pygments.filters

import re
import json

def lexer_for(code=None, **opts):
  lexers = pygments.lexers
  kwargs = opts.get('options') or dict()

  if 'lexer' in opts:
    return lexers.get_lexer_by_name(opts['lexer'], **kwargs)
  elif 'mimetype' in opts:
    return lexers.get_lexer_for_mimetype(opts['mimetype'], **kwargs)
  elif 'filename' in opts:
    name = opts['filename']
    if code:
      return lexers.guess_lexer_for_filename(name, code, **kwargs)
    else:
      return lexers.get_lexer_for_filename(name, **kwargs)
  elif code:
    return lexers.guess_lexer(code, **kwargs)
  else:
    return None

while True:
  line = sys.stdin.readline()

  req = json.loads(line)
  res = None

  if 'method' in req:
    method = req['method']

    if   method == 'get_all_styles':
      res = [ s for s in pygments.styles.get_all_styles() ]

    elif method == 'get_all_filters':
      res = [ f for f in pygments.filters.get_all_filters() ]

    elif method == 'get_all_lexers':
      res = [ l for l in pygments.lexers.get_all_lexers() ]

    elif method == 'get_all_formatters':
      res = [ [f.__name__, f.name, f.aliases] for f in pygments.formatters.get_all_formatters() ]

    elif method == 'highlight':
      code = req['args']
      opts = req['kwargs']
      kwargs = opts.get('options') or dict()

      lexer = lexer_for(code, **opts)

      fmt_name = str.lower(str(opts.get('formatter') or 'html'))
      formatter = pygments.formatters.get_formatter_by_name(fmt_name, **kwargs)

      res = pygments.highlight(code, lexer, formatter)

      if res and fmt_name == 'html':
        res = re.sub(r'</pre></div>\n?\Z', "</pre>\n</div>", res)

    elif method == 'css':
      args = req['args']
      kwargs = req.get('kwargs') or dict()

      fmt = pygments.formatters.get_formatter_by_name(args[0], **kwargs)
      res = fmt.get_style_defs(args[1])

    elif method == 'lexer_name_for':
      args = req['args']
      kwargs = req.get('kwargs') or dict()

      lxr = lexer_for(*args, **kwargs)
      if lxr:
        res = lxr.aliases[0]

    else:
      res = dict(error="invalid method")

  if res:
    sys.stdout.write(json.dumps(res))
  sys.stdout.write("\n")
  sys.stdout.flush()

