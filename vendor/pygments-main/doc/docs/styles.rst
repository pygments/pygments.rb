.. -*- mode: rst -*-

======
Styles
======

Pygments comes with some builtin styles that work for both the HTML and
LaTeX formatter.

The builtin styles can be looked up with the `get_style_by_name` function:

.. sourcecode:: pycon

    >>> from pygments.styles import get_style_by_name
    >>> get_style_by_name('colorful')
    <class 'pygments.styles.colorful.ColorfulStyle'>

You can pass a instance of a `Style` class to a formatter as the `style`
option in form of a string:

.. sourcecode:: pycon

    >>> from pygments.styles import get_style_by_name
    >>> from pygments.formatters import HtmlFormatter
    >>> HtmlFormatter(style='colorful').style
    <class 'pygments.styles.colorful.ColorfulStyle'>

Or you can also import your own style (which must be a subclass of
`pygments.style.Style`) and pass it to the formatter:

.. sourcecode:: pycon

    >>> from yourapp.yourmodule import YourStyle
    >>> from pygments.formatters import HtmlFormatter
    >>> HtmlFormatter(style=YourStyle).style
    <class 'yourapp.yourmodule.YourStyle'>


Creating Own Styles
===================

So, how to create a style? All you have to do is to subclass `Style` and
define some styles:

.. sourcecode:: python

    from pygments.style import Style
    from pygments.token import Keyword, Name, Comment, String, Error, \
         Number, Operator, Generic

    class YourStyle(Style):
        default_style = ""
        styles = {
            Comment:                'italic #888',
            Keyword:                'bold #005',
            Name:                   '#f00',
            Name.Function:          '#0f0',
            Name.Class:             'bold #0f0',
            String:                 'bg:#eee #111'
        }

That's it. There are just a few rules. When you define a style for `Name`
the style automatically also affects `Name.Function` and so on. If you
defined ``'bold'`` and you don't want boldface for a subtoken use ``'nobold'``.

(Philosophy: the styles aren't written in CSS syntax since this way
they can be used for a variety of formatters.)

`default_style` is the style inherited by all token types.

To make the style usable for Pygments, you must

* either register it as a plugin (see :doc:`the plugin docs <plugins>`)
* or drop it into the `styles` subpackage of your Pygments distribution one style
  class per style, where the file name is the style name and the class name is
  `StylenameClass`. For example, if your style should be called
  ``"mondrian"``, name the class `MondrianStyle`, put it into the file
  ``mondrian.py`` and this file into the ``pygments.styles`` subpackage
  directory.


Style Rules
===========

Here a small overview of all allowed styles:

``bold``
    render text as bold
``nobold``
    don't render text as bold (to prevent subtokens being highlighted bold)
``italic``
    render text italic
``noitalic``
    don't render text as italic
``underline``
    render text underlined
``nounderline``
    don't render text underlined
``bg:``
    transparent background
``bg:#000000``
    background color (black)
``border:``
    no border
``border:#ffffff``
    border color (white)
``#ff0000``
    text color (red)
``noinherit``
    don't inherit styles from supertoken

Note that there may not be a space between ``bg:`` and the color value
since the style definition string is split at whitespace.
Also, using named colors is not allowed since the supported color names
vary for different formatters.

Furthermore, not all lexers might support every style.


Builtin Styles
==============

Pygments ships some builtin styles which are maintained by the Pygments team.

To get a list of known styles you can use this snippet:

.. sourcecode:: pycon

    >>> from pygments.styles import STYLE_MAP
    >>> STYLE_MAP.keys()
    ['default', 'emacs', 'friendly', 'colorful']


Getting a list of available styles
==================================

.. versionadded:: 0.6

Because it could be that a plugin registered a style, there is
a way to iterate over all styles:

.. sourcecode:: pycon

    >>> from pygments.styles import get_all_styles
    >>> styles = list(get_all_styles())


.. _AnsiTerminalStyle:

Terminal Styles
===============

.. versionadded:: 2.2

Custom styles used with the 256-color terminal formatter can also map colors to
use the 8 default ANSI colors.  To do so, use ``#ansigreen``, ``#ansired`` or
any other colors defined in :attr:`pygments.style.ansicolors`.  Foreground ANSI
colors will be mapped to the corresponding `escape codes 30 to 37
<https://en.wikipedia.org/wiki/ANSI_escape_code#Colors>`_ thus respecting any
custom color mapping and themes provided by many terminal emulators.  Light
variants are treated as foreground color with and an added bold flag.
``bg:#ansi<color>`` will also be respected, except the light variant will be the
same shade as their dark variant.

See the following example where the color of the string ``"hello world"`` is
governed by the escape sequence ``\x1b[34;01m`` (Ansi Blue, Bold, 41 being red
background) instead of an extended foreground & background color.

.. sourcecode:: pycon

    >>> from pygments import highlight
    >>> from pygments.style import Style
    >>> from pygments.token import Token
    >>> from pygments.lexers import Python3Lexer
    >>> from pygments.formatters import Terminal256Formatter

    >>> class MyStyle(Style):
            styles = {
                Token.String:     '#ansiblue bg:#ansired',
            }

    >>> code = 'print("Hello World")'
    >>> result = highlight(code, Python3Lexer(), Terminal256Formatter(style=MyStyle))
    >>> print(result.encode())
    b'\x1b[34;41;01m"\x1b[39;49;00m\x1b[34;41;01mHello World\x1b[39;49;00m\x1b[34;41;01m"\x1b[39;49;00m'

Colors specified using ``#ansi*`` are converted to a default set of RGB colors
when used with formatters other than the terminal-256 formatter.

By definition of ANSI, the following colors are considered "light" colors, and
will be rendered by most terminals as bold:

- "darkgray", "red", "green", "yellow", "blue", "fuchsia", "turquoise", "white"

The following are considered "dark" colors and will be rendered as non-bold:

- "black", "darkred", "darkgreen", "brown", "darkblue", "purple", "teal",
  "lightgray"

Exact behavior might depends on the terminal emulator you are using, and its
settings.
