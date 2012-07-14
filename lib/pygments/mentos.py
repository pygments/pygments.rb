#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, re, os, signal, codecs
import traceback
if 'PYGMENTS_PATH' in os.environ:
  sys.path.insert(0, os.environ['PYGMENTS_PATH'])
sys.path.append(os.getcwd() + "/vendor/")
sys.path.append(os.getcwd() + "/vendor/pygments-main")
sys.path.append(os.getcwd() + "/vendor/simplejson")

import pygments
from pygments import lexers, formatters, styles, filters

try:
    import json
except ImportError:
    import simplejson as json

def _convert_keys(dictionary):
    if not isinstance(dictionary, dict):
        return dictionary
    return dict((str(k), _convert_keys(v))
        for k, v in dictionary.items())

def _write_error(error):
    res = {"error": error}
    out_header = json.dumps(res).encode('utf-8')
    print out_header
    sys.stdout.flush()
    return

def _signal_handler(signal, frame):
    """
    Handle the signal given in the first argument, exiting gracefully
    """
    sys.exit(0)

class Mentos(object):
    """
    Interacts with pygments.rb to provide access to pygments functionality
    """
    def __init__(self):
        pass

    def return_lexer(self, lexer, args, inputs, code=None):
        """
        Accepting a variety of possible inputs, return a Lexer object.

        The inputs argument should be a hash with at least one of the following
        keys:

            - 'lexer' ("python")
            - 'mimetype' ("text/x-ruby")
            - 'filename' ("yeaaah.py")
            - 'code' ("import derp" etc)

        The code guessing method is not especially great. It is advised that
        clients pass in a literal lexer name whenever possible, which provides
        the best probability of match (100 percent).
        """

        if lexer:
            return lexers.get_lexer_by_name(lexer)

        if inputs:
            if 'lexer' in inputs:
                return lexers.get_lexer_by_name(inputs['lexer'])

            elif 'mimetype' in inputs:
                return lexers.get_lexer_for_mimetype(inputs['mimetype'])

            elif 'filename' in inputs:
                name = inputs['filename']

                # If we have code and a filename, pygments allows us to guess
                # with both. This is better than just guessing with code.
                if code:
                    return lexers.guess_lexer_for_filename(name, code)
                else:
                    return lexers.get_lexer_for_filename(name)

        # If all we got is code, try anyway.
        if code:
            return lexers.guess_lexer(code)

        else:
            _write_error("No lexer")


    def highlight_text(self, code, lexer, formatter_name, args, kwargs):
        """
        Highlight the relevant code, and return a result string.
        The default formatter is html, but alternate formatters can be passed in via
        the formatter_name argument. Additional paramters can be passed as args
        or kwargs.
        """
        # Default to html if we don't have the formatter name.
        if formatter_name:
            _format_name = str(formatter_name)
        else:
            _format_name = "html"

        # Return a lexer object
        lexer = self.return_lexer(lexer, args, kwargs, code)

        # Make sure we sucessfuly got a lexer
        if lexer:
            formatter = pygments.formatters.get_formatter_by_name(str.lower(_format_name), **kwargs)

            # Do the damn thing.
            res = pygments.highlight(code, lexer, formatter)

            # Fix up the formatting a bit for html.
            if res and _format_name == 'html':
                res = re.sub(r'</pre></div>\n?\Z', "</pre>\n</div>", res)

            return res

        else:
            _write_error("No lexer")

    def get_data(self, method, lexer, args, kwargs, text=None):
        """
        Based on the method argument, determine the action we'd like pygments
        to do. Then return the data generated from pygments.
        """
        if kwargs:
            formatter_name = kwargs.get("formatter", None)
            opts = kwargs.get("options", {})

        # Ensure there's a 'method' key before proceeeding
        if method:
            res = None

            # Now check what that method is. For the get methods, pygments
            # itself returns generators, so we make them lists so we can serialize
            # easier.
            if method == 'get_all_styles':
                res = json.dumps(list(pygments.styles.get_all_styles()))

            elif method == 'get_all_filters':
                res = json.dumps(list(pygments.filters.get_all_filters()))

            elif method == 'get_all_lexers':
                res = json.dumps(list(pygments.lexers.get_all_lexers()))

            elif method == 'get_all_formatters':
                res = [ [ft.__name__, ft.name, ft.aliases] for ft in pygments.formatters.get_all_formatters() ]
                res = json.dumps(res)

            elif method == 'highlight':
                text = text.decode('utf-8')
                res = self.highlight_text(text, lexer, formatter_name, args, _convert_keys(opts))

            elif method == 'css':
                kwargs = _convert_keys(kwargs)
                fmt = pygments.formatters.get_formatter_by_name(args[0], **kwargs)
                res = fmt.get_style_defs(args[1])

            elif method == 'lexer_name_for':
                lexer = self.return_lexer(None, args, kwargs, text)

                if lexer:
                    # We don't want the Lexer itself, just the name.
                    # Take the first alias.
                    res = lexer.aliases[0]

                else:
                    _write_error("No lexer")

            else:
                _write_error("No lexer")

            return res

    def start(self):
        """
        Main loop, waiting for inputs on stdin. When it gets some data,
        it goes to work.

        mentos exposes most of the "High-level API" of pygments. It always
        expects and requires a JSON header of metadata. If there is data to be
        pygmentized, this header will be followed by the text to be pygmentized.

        The header is of form:
            { "method": "highlight", "args": [], "kwargs": {"arg1": "v"}, "bytes": 128, "fd": "8"}
        """
        while True:
            res = None

            # The loop begins by reading off a simple 32-arity string representing
            # an integer of 32 bits. This is the length of our JSON header. Using
            # this method allows to avoid worrying about newlines.
            size = sys.stdin.read(32)

            # Read from stdin the amount of bytes we were told to expect.
            header_bytes = int(size, 2)
            line = sys.stdin.read(header_bytes)

            # A message is in. Get the header. If we get bad input, don't die horribly,
            # but do set the header to None.
            try:
                header = json.loads(line)
            except:
                header = None

            if header:
                try:
                    method = header["method"]

                    # Default to empty array and empty dictionary if nothing is given. Default to
                    # no text and no further bytes to read.
                    args = header.get("args", [])
                    kwargs = header.get("kwargs", {})
                    lexer = kwargs.get("lexer", None)
                    if lexer:
                        lexer = str(lexer)

                    if method == 'highlight':
                        text = args.encode('utf-8')
                    else:
                        text = None

                    # And now get the actual data from pygments.
                    try:
                        res = self.get_data(method, lexer, args, kwargs, text)
                    except:
                        tb = traceback.format_exc()
                        _write_error(tb)
                        return

                    # Base header. We'll build on this, adding keys as necessary.
                    header = {"method": method}

                    res_bytes = len(res) + 1
                    header["bytes"] = res_bytes

                    out_header = json.dumps(header).encode('utf-8')

                    print out_header
                    print res
                    sys.stdout.flush()

                except:
                    tb = traceback.format_exc()
                    _write_error(tb)

            else:
                _write_error("Bad header/no data")


def main():

    # Signal handlers to trap signals.
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    signal.signal(signal.SIGHUP, _signal_handler)

    mentos = Mentos()
    mentos.start()

if __name__ == "__main__":
    main()



