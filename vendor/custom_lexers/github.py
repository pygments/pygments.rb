# -*- coding: utf-8 -*-
"""
    pygments.lexers.github
    ~~~~~~~~~~~~~~~~~~~

    Custom lexers for GitHub.com

    :copyright: Copyright 2012 by GitHub, Inc
    :license: BSD, see LICENSE for details.
"""
import re

from pygments.lexer import RegexLexer, include, bygroups, using, DelegatingLexer
from pygments.token import Text, Name, Number, String, Comment, Punctuation, \
     Other, Keyword, Operator, Literal

__all__ = ['Dasm16Lexer', 'PuppetLexer', 'AugeasLexer', "TOMLLexer"]

class Dasm16Lexer(RegexLexer):
    """
    Simple lexer for DCPU-16 Assembly

    Check http://0x10c.com/doc/dcpu-16.txt
    """
    name = 'dasm16'
    aliases = ['DASM16']
    filenames = ['*.dasm16', '*.dasm']
    mimetypes = ['text/x-dasm16']

    INSTRUCTIONS = [
        'SET',
        'ADD', 'SUB',
        'MUL', 'MLI',
        'DIV', 'DVI',
        'MOD', 'MDI',
        'AND', 'BOR', 'XOR',
        'SHR', 'ASR', 'SHL',
        'IFB', 'IFC', 'IFE', 'IFN', 'IFG', 'IFA', 'IFL', 'IFU',
        'ADX', 'SBX',
        'STI', 'STD',
        'JSR',
        'INT', 'IAG', 'IAS', 'RFI', 'IAQ', 'HWN', 'HWQ', 'HWI',
    ]

    REGISTERS = [
        'A', 'B', 'C',
        'X', 'Y', 'Z',
        'I', 'J',
        'SP', 'PC', 'EX',
        'POP', 'PEEK', 'PUSH'
    ]

    # Regexes yo
    char = r'[a-zA-Z$._0-9@]'
    identifier = r'(?:[a-zA-Z$_]' + char + '*|\.' + char + '+)'
    number = r'[+-]?(?:0[xX][a-zA-Z0-9]+|\d+)'
    binary_number = r'0b[01_]+'
    instruction = r'(?i)(' + '|'.join(INSTRUCTIONS) + ')'
    single_char = r"'\\?" + char + "'"
    string = r'"(\\"|[^"])*"'

    def guess_identifier(lexer, match):
        ident = match.group(0)
        klass = Name.Variable if ident.upper() in lexer.REGISTERS else Name.Label
        yield match.start(), klass, ident

    tokens = {
        'root': [
            include('whitespace'),
            (':' + identifier, Name.Label),
            (identifier + ':', Name.Label),
            (instruction, Name.Function, 'instruction-args'),
            (r'\.' + identifier, Name.Function, 'data-args'),
            (r'[\r\n]+', Text)
        ],

        'numeric' : [
            (binary_number, Number.Integer),
            (number, Number.Integer),
            (single_char, String),
        ],

        'arg' : [
            (identifier, guess_identifier),
            include('numeric')
        ],

        'deref' : [
            (r'\+', Punctuation),
            (r'\]', Punctuation, '#pop'),
            include('arg'),
            include('whitespace')
        ],

        'instruction-line' : [
            (r'[\r\n]+', Text, '#pop'),
            (r';.*?$', Comment, '#pop'),
            include('whitespace')
        ],

        'instruction-args': [
            (r',', Punctuation),
            (r'\[', Punctuation, 'deref'),
            include('arg'),
            include('instruction-line')
        ],

        'data-args' : [
            (r',', Punctuation),
            include('numeric'),
            (string, String),
            include('instruction-line')
        ],

        'whitespace': [
            (r'\n', Text),
            (r'\s+', Text),
            (r';.*?\n', Comment)
        ],
    }

class AugeasLexer(RegexLexer):
    name = 'Augeas'
    aliases = ['augeas']
    filenames = ['*.aug']

    tokens = {
        'root': [
            (r'(module)(\s*)([^\s=]+)', bygroups(Keyword.Namespace, Text, Name.Namespace)),
            (r'(let)(\s*)([^\s=]+)', bygroups(Keyword.Declaration, Text, Name.Variable)),
            (r'(del|store|value|counter|seq|key|label|autoload|incl|excl|transform|test|get|put)(\s+)', bygroups(Name.Builtin, Text)),
            (r'(\()([^\:]+)(\:)(unit|string|regexp|lens|tree|filter)(\))', bygroups(Punctuation, Name.Variable, Punctuation, Keyword.Type, Punctuation)),
            (r'\(\*', Comment.Multiline, 'comment'),
            (r'[\+=\|\.\*\;\?-]', Operator),
            (r'[\[\]\(\)\{\}]', Operator),
            (r'"', String.Double, 'string'),
            (r'\/', String.Regex, 'regex'),
            (r'([A-Z]\w*)(\.)(\w+)', bygroups(Name.Namespace, Punctuation, Name.Variable)),
            (r'.', Name.Variable),
            (r'\s', Text),
        ],
        'string': [
            (r'\\.', String.Escape),
            (r'[^"]', String.Double),
            (r'"', String.Double, '#pop'),
        ],
        'regex': [
            (r'\\.', String.Escape),
            (r'[^\/]', String.Regex),
            (r'\/', String.Regex, '#pop'),
        ],
        'comment': [
            (r'[^*\)]', Comment.Multiline),
            (r'\(\*', Comment.Multiline, '#push'),
            (r'\*\)', Comment.Multiline, '#pop'),
            (r'[\*\)]', Comment.Multiline)
        ],
    }

class TOMLLexer(RegexLexer):
    """
    Lexer for TOML, a simple language for config files
    """

    name = 'TOML'
    aliases = ['toml']
    filenames = ['*.toml']

    tokens = {
        'root': [

            # Basics, comments, strings
            (r'\s+', Text),
            (r'#.*?$', Comment.Single),
            (r'"(\\\\|\\"|[^"])*"', String),
            (r'(true|false)$', Keyword.Constant),
            ('[a-zA-Z_][a-zA-Z0-9_\-]*', Name),

            # Datetime
            (r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', Number.Integer),

            # Numbers
            (r'(\d+\.\d*|\d*\.\d+)([eE][+-]?[0-9]+)?j?', Number.Float),
            (r'\d+[eE][+-]?[0-9]+j?', Number.Float),
            (r'\-?\d+', Number.Integer),

            # Punctuation
            (r'[]{}:(),;[]', Punctuation),
            (r'\.', Punctuation),

            # Operators
            (r'=', Operator)

        ]
    }


