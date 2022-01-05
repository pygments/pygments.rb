#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import struct
import sys, re, os, signal
import traceback
if 'PYGMENTS_PATH' in os.environ:
    sys.path.insert(0, os.environ['PYGMENTS_PATH'])

dirname = os.path.dirname

base_dir = dirname(dirname(dirname(os.path.abspath(__file__))))
sys.path.append(base_dir + "/vendor/pygments-main")

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
        for k, v in list(dictionary.items()))

def _write_error(error):
    res = {"error": error}
    out_header_bytes = json.dumps(res).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('!i', len(out_header_bytes)))
    sys.stdout.buffer.write(out_header_bytes)
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

        The code argument should be a string, such as "import derp".

        The code guessing method is not especially great. It is advised that
        clients pass in a literal lexer name whenever possible, which provides
        the best probability of match (100 percent).
        """

        if lexer:
            if inputs:
                return lexers.get_lexer_by_name(lexer, **inputs)
            else:
                return lexers.get_lexer_by_name(lexer)

        if inputs:
            if 'lexer' in inputs:
                return lexers.get_lexer_by_name(inputs['lexer'], **inputs)

            elif 'mimetype' in inputs:
                return lexers.get_lexer_for_mimetype(inputs['mimetype'], **inputs)

            elif 'filename' in inputs:
                name = inputs['filename']

                # If we have code and a filename, pygments allows us to guess
                # with both. This is better than just guessing with code.
                if code:
                    return lexers.guess_lexer_for_filename(name, code, **inputs)
                else:
                    return lexers.get_lexer_for_filename(name, **inputs)

        # If all we got is code, try anyway.
        if code:
            return lexers.guess_lexer(code, **inputs)

        else:
            return None


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
                res = self.highlight_text(text, lexer, formatter_name, args, _convert_keys(opts))
                if type(res) is bytes:
                    res = res.decode('utf-8')

            elif method == 'css':
                kwargs = _convert_keys(kwargs)
                fmt = pygments.formatters.get_formatter_by_name(args[0], **kwargs)
                res = fmt.get_style_defs(args[1])

            elif method == 'lexer_names_for':
                lexer = self.return_lexer(None, args, kwargs, text)

                if lexer:
                    # We don't want the Lexer itself, just aliases.
                    res = json.dumps(list(lexer.aliases))

                else:
                    _write_error("No lexer")

            elif method == 'version':
                res = json.dumps([pygments.__version__])

            else:
                _write_error("Invalid method " + method)

            return res


    def _send_data(self, res, method):
        # Base header. We'll build on this, adding keys as necessary.
        base_header = {"method": method}

        res_bytes = res.encode("utf-8")
        bytes = len(res_bytes)
        base_header["bytes"] = bytes

        out_header_bytes = json.dumps(base_header).encode('utf-8')

        # Send it to Rubyland
        sys.stdout.buffer.write(struct.pack('!i', len(out_header_bytes)))
        sys.stdout.buffer.write(out_header_bytes)
        sys.stdout.buffer.write(res_bytes)
        sys.stdout.flush()

    def _parse_header(self, header):
        method = header["method"]
        args = header.get("args", [])
        kwargs = header.get("kwargs", {})
        lexer = kwargs.get("lexer", None)
        return (method, args, kwargs, lexer)

    def start(self):
        """
        Main loop, waiting for inputs on stdin. When it gets some data,
        it goes to work.

        mentos exposes most of the "High-level API" of pygments. It always
        expects and requires a JSON header of metadata. If there is data to be
        pygmentized, this header will be followed by the text to be pygmentized.

        The header is of form:
        { "method": "highlight", "args": [], "kwargs": {"arg1": "v"}, "bytes": 128}
        """

        while True:
            header_size_bytes = sys.stdin.buffer.read(4)
            if not header_size_bytes:
                break

            header_size = struct.unpack('!i', header_size_bytes)[0]

            try:
                line = sys.stdin.buffer.read(header_size).decode('utf-8')
                header = json.loads(line)

                method, args, kwargs, lexer = self._parse_header(header)
                _bytes = 0

                if lexer:
                    lexer = str(lexer)

                # Read more bytes if necessary
                if kwargs:
                    _bytes = kwargs.get("bytes", 0)

                # Read up to the given number of *bytes* (not chars) (possibly 0)
                text = sys.stdin.buffer.read(_bytes).decode('utf-8')

                # Get the actual data from pygments.
                res = self.get_data(method, lexer, args, kwargs, text)

                self._send_data(res, method)

            except:
                tb = traceback.format_exc()
                _write_error(tb)

def main():

    # Signal handlers to trap signals.
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    if sys.platform != "win32":
        signal.signal(signal.SIGHUP, _signal_handler)

    mentos = Mentos()
    mentos.start()

if __name__ == "__main__":
    main()
