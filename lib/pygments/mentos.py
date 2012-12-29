#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, re, os, signal
import traceback
if 'PYGMENTS_PATH' in os.environ:
    sys.path.insert(0, os.environ['PYGMENTS_PATH'])

dirname = os.path.dirname

base_dir = dirname(dirname(dirname(os.path.abspath(__file__))))
sys.path.append(base_dir + "/vendor")
sys.path.append(base_dir + "/vendor/pygments-main")
sys.path.append(base_dir + "/vendor/simplejson")

import pygments
from pygments import lexers, formatters, styles, filters

from threading import Lock

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
    bits = _get_fixed_bits_from_header(out_header)
    sys.stdout.write(bits + "\n")
    sys.stdout.flush()
    sys.stdout.write(out_header + "\n")
    sys.stdout.flush()
    return

def _get_fixed_bits_from_header(out_header):
    size = len(out_header)
    return "".join(map(lambda y:str((size>>y)&1), range(32-1, -1, -1)))

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
                try:
                    text = text.decode('utf-8')
                except UnicodeDecodeError:
                    # The text may already be encoded
                    text = text
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
                _write_error("Invalid method " + method)

            return res


    def _send_data(self, res, method):

        # Base header. We'll build on this, adding keys as necessary.
        base_header = {"method": method}

        res_bytes = len(res) + 1
        base_header["bytes"] = res_bytes

        out_header = json.dumps(base_header).encode('utf-8')

        # Following the protocol, send over a fixed size represenation of the
        # size of the JSON header
        bits = _get_fixed_bits_from_header(out_header)

        # Send it to Rubyland
        sys.stdout.write(bits + "\n")
        sys.stdout.flush()

        # Send the header.
        sys.stdout.write(out_header + "\n")
        sys.stdout.flush()

        # Finally, send the result
        sys.stdout.write(res + "\n")
        sys.stdout.flush()


    def _get_ids(self, text):
        start_id = text[:8]
        end_id = text[-8:]
        return start_id, end_id

    def _check_and_return_text(self, text, start_id, end_id):

        # Sanity check.
        id_regex = re.compile('[A-Z]{8}')

        if not id_regex.match(start_id) and not id_regex.match(end_id):
            _write_error("ID check failed. Not an ID.")

        if not start_id == end_id:
            _write_error("ID check failed. ID's did not match.")

        # Passed the sanity check. Remove the id's and return
        text = text[10:-10]
        return text

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
        { "method": "highlight", "args": [], "kwargs": {"arg1": "v"}, "bytes": 128, "fd": "8"}
        """
        lock = Lock()

        while True:
            # The loop begins by reading off a simple 32-arity string
            # representing an integer of 32 bits. This is the length of
            # our JSON header.
            size = sys.stdin.read(32)

            lock.acquire()

            try:
                # Read from stdin the amount of bytes we were told to expect.
                header_bytes = int(size, 2)

                # Sanity check the size
                size_regex = re.compile('[0-1]{32}')
                if not size_regex.match(size):
                    _write_error("Size received is not valid.")

                line = sys.stdin.read(header_bytes)

                header = json.loads(line)

                method, args, kwargs, lexer = self._parse_header(header)
                _bytes = 0

                if lexer:
                    lexer = str(lexer)

                # Read more bytes if necessary
                if kwargs:
                    _bytes = kwargs.get("bytes", 0)

                # Read up to the given number bytes (possibly 0)
                text = sys.stdin.read(_bytes)

                # Sanity check the return.
                if _bytes:
                    start_id, end_id = self._get_ids(text)
                    text = self._check_and_return_text(text, start_id, end_id)

                # Get the actual data from pygments.
                res = self.get_data(method, lexer, args, kwargs, text)

                # Put back the sanity check values.
                if method == "highlight":
                    res = start_id + "  " + res + "  " + end_id

                self._send_data(res, method)

            except:
                tb = traceback.format_exc()
                _write_error(tb)

            finally:
                lock.release()

def main():

    # Signal handlers to trap signals.
    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)
    if sys.platform != "win32":
        signal.signal(signal.SIGHUP, _signal_handler)

    mentos = Mentos()

    if sys.platform == "win32":
        # disable CRLF
        import msvcrt
        msvcrt.setmode(sys.stdout.fileno(), os.O_BINARY)
    else:
        # close fd's inherited from the ruby parent
        import resource
        maxfd = resource.getrlimit(resource.RLIMIT_NOFILE)[1]
        if maxfd == resource.RLIM_INFINITY:
            maxfd = 65536

        for fd in range(3, maxfd):
            try:
                os.close(fd)
            except:
                pass

    mentos.start()

if __name__ == "__main__":
    main()



