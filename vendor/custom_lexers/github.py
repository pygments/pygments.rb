# -*- coding: utf-8 -*-
"""
    pygments.lexers.github
    ~~~~~~~~~~~~~~~~~~~

    Custom lexers for GitHub.com

    :copyright: Copyright 2012 by GitHub, Inc
    :license: BSD, see LICENSE for details.
"""
import re

from pygments.lexer import RegexLexer, ExtendedRegexLexer, include, bygroups, \
    using, DelegatingLexer
from pygments.token import Text, Name, Number, String, Comment, Punctuation, \
     Other, Keyword, Operator, Literal, Whitespace

__all__ = ['Dasm16Lexer', 'PuppetLexer', 'AugeasLexer', "TOMLLexer", "SlashLexer"]

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

class PuppetLexer(RegexLexer):
    name = 'Puppet'
    aliases = ['puppet']
    filenames = ['*.pp']

    tokens = {
        'root': [
            include('puppet'),
        ],
        'puppet': [
            include('comments'),
            (r'(class)(\s*)(\{)', bygroups(Name.Class, Text, Punctuation), ('type', 'namevar')),
            (r'(class|define)', Keyword.Declaration, ('block','class_name')),
            (r'node', Keyword.Declaration, ('block', 'node_name')),
            (r'elsif', Keyword.Reserved, ('block', 'conditional')),
            (r'if', Keyword.Reserved, ('block', 'conditional')),
            (r'unless', Keyword.Reserved, ('block', 'conditional')),
            (r'(else)(\s*)(\{)', bygroups(Keyword.Reserved, Text, Punctuation), 'block'),
            (r'case', Keyword.Reserved, ('case', 'conditional')),
            (r'(::)?([A-Z][\w:]+)+(\s*)(<{1,2}\|)', bygroups(Name.Class, Name.Class, Text, Punctuation), 'spaceinvader'),
            (r'(::)?([A-Z][\w:]+)+(\s*)(\{)', bygroups(Name.Class, Name.Class, Text, Punctuation), 'type'),
            (r'(::)?([A-Z][\w:]+)+(\s*)(\[)', bygroups(Name.Class, Name.Class, Text, Punctuation), ('type', 'override_name')),
            (r'(@{0,2}[\w:]+)(\s*)(\{)(\s*)', bygroups(Name.Class, Text, Punctuation, Text), ('type', 'namevar')),
            (r'\$(::)?(\w+::)*\w+', Name.Variable, 'var_assign'),
            (r'(include|require)', Keyword.Namespace, 'include'),
            (r'import', Keyword.Namespace, 'import'),
            (r'(\w+)(\()', bygroups(Name.Function, Punctuation), 'function'),
            (r'\s', Text),
        ],
        'block': [
            include('puppet'),
            (r'\}', Text, '#pop'),
        ],
        'override_name': [
            include('strings'),
            include('variables'),
            (r'\]', Punctuation),
            (r'\s', Text),
            (r'\{', Punctuation, '#pop'),
        ],
        'node_name': [
            (r'inherits', Keyword.Declaration),
            (r'[\w\.]+', String),
            include('strings'),
            include('variables'),
            (r',', Punctuation),
            (r'\s', Text),
            (r'\{', Punctuation, '#pop'),
        ],
        'class_name': [
            (r'inherits', Keyword.Declaration),
            (r'[\w:]+', Name.Class),
            (r'\s', Text),
            (r'\{', Punctuation, '#pop'),
            (r'\(', Punctuation, 'paramlist'),
        ],
        'include': [
            (r'\n', Text, '#pop'),
            (r'[\w:-]+', Name.Class),
            include('value'),
            (r'\s', Text),
        ],
        'import': [
            (r'\n', Text, '#pop'),
            (r'[\/\w\.]+', String),
            include('value'),
            (r'\s', Text),
        ],
        'case': [
            (r'(default)(:)(\s*)(\{)', bygroups(Keyword.Reserved, Punctuation, Text, Punctuation), 'block'),
            include('case_values'),
            (r'(:)(\s*)(\{)', bygroups(Punctuation, Text, Punctuation), 'block'),
            (r'\s', Text),
            (r'\}', Punctuation, '#pop'),
        ],
        'case_values': [
            include('value'),
            (r',', Punctuation),
        ],
        'comments': [
            (r'\s*#.*\n', Comment.Singleline),
        ],
        'strings': [
            (r"'.*?'", String.Single),
            (r'\w+', String.Symbol),
            (r'"', String.Double, 'dblstring'),
            (r'\/.+?\/', String.Regex),
        ],
        'dblstring': [
            (r'\$\{.+?\}', String.Interpol),
            (r'(?:\\(?:[bdefnrstv\'"\$\\/]|[0-7][0-7]?[0-7]?|\^[a-zA-Z]))', String.Escape),
            (r'[^"\\\$]+', String.Double),
            (r'\$', String.Double),
            (r'"', String.Double, '#pop'),
        ],
        'variables': [
            (r'\$(::)?(\w+::)*\w+', Name.Variable),
        ],
        'var_assign': [
            (r'\[', Punctuation, ('#pop', 'array')),
            (r'\{', Punctuation, ('#pop', 'hash')),
            (r'(\s*)(=)(\s*)', bygroups(Text, Operator, Text)),
            (r'(\(|\))', Punctuation),
            include('operators'),
            include('value'),
            (r'\s', Text, '#pop'),
        ],
        'booleans': [
            (r'(true|false)', Literal),
        ],
        'operators': [
            (r'(\s*)(==|=~|\*|-|\+|<<|>>|!=|!~|!|>=|<=|<|>|and|or|in)(\s*)', bygroups(Text, Operator, Text)),
        ],
        'conditional': [
            include('operators'),
            include('strings'),
            include('variables'),
            (r'\[', Punctuation, 'array'),
            (r'\(', Punctuation, 'conditional'),
            (r'\{', Punctuation, '#pop'),
            (r'\)', Punctuation, '#pop'),
            (r'\s', Text),
        ],
        'spaceinvader': [
            include('operators'),
            include('strings'),
            include('variables'),
            (r'\[', Punctuation, 'array'),
            (r'\(', Punctuation, 'conditional'),
            (r'\s', Text),
            (r'\|>{1,2}', Punctuation, '#pop'),
        ],
        'namevar': [
            include('value'),
            (r'\[', Punctuation, 'array'),
            (r'\s', Text),
            (r':', Punctuation, '#pop'),
            (r'\}', Punctuation, '#pop'),
        ],
        'function': [
            (r'\[', Punctuation, 'array'),
            include('value'),
            (r',', Punctuation),
            (r'\s', Text),
            (r'\)', Punctuation, '#pop'),
        ],
        'paramlist': [
            include('value'),
            (r'=', Punctuation),
            (r',', Punctuation),
            (r'\s', Text),
            (r'\[', Punctuation, 'array'),
            (r'\)', Punctuation, '#pop'),
        ],
        'type': [
            (r'(\w+)(\s*)(=>)(\s*)', bygroups(Name.Tag, Text, Punctuation, Text), 'param_value'),
            (r'\}', Punctuation, '#pop'),
            (r'\s', Text),
            include('comments'),
            (r'', Text, 'namevar'),
        ],
        'value': [
            (r'[\d\.]', Number),
            (r'([A-Z][\w:]+)+(\[)', bygroups(Name.Class, Punctuation), 'array'),
            (r'(\w+)(\()', bygroups(Name.Function, Punctuation), 'function'),
            include('strings'),
            include('variables'),
            include('comments'),
            include('booleans'),
            (r'(\s*)(\?)(\s*)(\{)', bygroups(Text, Punctuation, Text, Punctuation), 'selector'),
            (r'\{', Punctuation, 'hash'),
        ],
        'selector': [
            (r'default', Keyword.Reserved),
            include('value'),
            (r'=>', Punctuation),
            (r',', Punctuation),
            (r'\s', Text),
            (r'\}', Punctuation, '#pop'),
        ],
        'param_value': [
            include('value'),
            (r'\[', Punctuation, 'array'),
            (r',', Punctuation, '#pop'),
            (r';', Punctuation, '#pop'),
            (r'\s', Text, '#pop'),
            (r'', Text, '#pop'),
        ],
        'array': [
            include('value'),
            (r'\[', Punctuation, 'array'),
            (r',', Punctuation),
            (r'\s', Text),
            (r'\]', Punctuation, '#pop'),
        ],
        'hash': [
            include('value'),
            (r'\s', Text),
            (r'=>', Punctuation),
            (r',', Punctuation),
            (r'\}', Punctuation, '#pop'),
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

class SlashLanguageLexer(ExtendedRegexLexer):
    _nkw = r'(?=[^a-zA-Z_0-9])'

    def move_state(new_state):
        return ("#pop", new_state)

    def right_angle_bracket(lexer, match, ctx):
        if len(ctx.stack) > 1 and ctx.stack[-2] == "string":
            ctx.stack.pop()
        yield match.start(), String.Interpol, u"}"
        ctx.pos = match.end()
        pass

    tokens = {
        "root": [
            (r"<%=",        Comment.Preproc,    move_state("slash")),
            (r"<%!!",       Comment.Preproc,    move_state("slash")),
            (r"<%#.*?%>",   Comment.Multiline),
            (r"<%",         Comment.Preproc,    move_state("slash")),
            (r".|\n",       Other),
        ],
        "string": [
            (r"\\",         String.Escape,      move_state("string_e")),
            (r"\"",         String,             move_state("slash")),
            (r"#\{",        String.Interpol,    "slash"),
            (r'.|\n',       String),
        ],
        "string_e": [
            (r'n',                  String.Escape,      move_state("string")),
            (r't',                  String.Escape,      move_state("string")),
            (r'r',                  String.Escape,      move_state("string")),
            (r'e',                  String.Escape,      move_state("string")),
            (r'x[a-fA-F0-9]{2}',    String.Escape,      move_state("string")),
            (r'.',                  String.Escape,      move_state("string")),
        ],
        "regexp": [
            (r'}[a-z]*',            String.Regex,       move_state("slash")),
            (r'\\(.|\n)',           String.Regex),
            (r'{',                  String.Regex,       "regexp_r"),
            (r'.|\n',               String.Regex),
        ],
        "regexp_r": [
            (r'}[a-z]*',            String.Regex,       "#pop"),
            (r'\\(.|\n)',           String.Regex),
            (r'{',                  String.Regex,       "regexp_r"),
        ],
        "slash": [
            (r"%>",                     Comment.Preproc,    move_state("root")),
            (r"\"",                     String,             move_state("string")),
            (r"'[a-zA-Z0-9_]+",         String),
            (r'%r{',                    String.Regex,       move_state("regexp")),
            (r'/\*.*?\*/',              Comment.Multiline),
            (r"(#|//).*?\n",            Comment.Single),
            (r'-?[0-9]+e[+-]?[0-9]+',   Number.Float),
            (r'-?[0-9]+\.[0-9]+(e[+-]?[0-9]+)?', Number.Float),
            (r'-?[0-9]+',               Number.Integer),
            (r'nil'+_nkw,               Name.Builtin),
            (r'true'+_nkw,              Name.Builtin),
            (r'false'+_nkw,             Name.Builtin),
            (r'self'+_nkw,              Name.Builtin),
            (r'(class)(\s+)([A-Z][a-zA-Z0-9_\']*)',
                bygroups(Keyword, Whitespace, Name.Class)),
            (r'class'+_nkw,             Keyword),
            (r'extends'+_nkw,           Keyword),
            (r'(def)(\s+)(self)(\s*)(\.)(\s*)([a-z_][a-zA-Z0-9_\']*=?|<<|>>|==|<=>|<=|<|>=|>|\+|-(self)?|~(self)?|\*|/|%|^|&&|&|\||\[\]=?)',
                bygroups(Keyword, Whitespace, Name.Builtin, Whitespace, Punctuation, Whitespace, Name.Function)),
            (r'(def)(\s+)([a-z_][a-zA-Z0-9_\']*=?|<<|>>|==|<=>|<=|<|>=|>|\+|-(self)?|~(self)?|\*|/|%|^|&&|&|\||\[\]=?)',
                bygroups(Keyword, Whitespace, Name.Function)),
            (r'def'+_nkw,               Keyword),
            (r'if'+_nkw,                Keyword),
            (r'elsif'+_nkw,             Keyword),
            (r'else'+_nkw,              Keyword),
            (r'unless'+_nkw,            Keyword),
            (r'for'+_nkw,               Keyword),
            (r'in'+_nkw,                Keyword),
            (r'while'+_nkw,             Keyword),
            (r'until'+_nkw,             Keyword),
            (r'and'+_nkw,               Keyword),
            (r'or'+_nkw,                Keyword),
            (r'not'+_nkw,               Keyword),
            (r'lambda'+_nkw,            Keyword),
            (r'try'+_nkw,               Keyword),
            (r'catch'+_nkw,             Keyword),
            (r'return'+_nkw,            Keyword),
            (r'next'+_nkw,              Keyword),
            (r'last'+_nkw,              Keyword),
            (r'throw'+_nkw,             Keyword),
            (r'use'+_nkw,               Keyword),
            (r'switch'+_nkw,            Keyword),
            (r'\\',                     Keyword),
            (r'λ',                      Keyword),
            (r'__FILE__'+_nkw,          Name.Builtin.Pseudo),
            (r'__LINE__'+_nkw,          Name.Builtin.Pseudo),
            (r'[A-Z][a-zA-Z0-9_\']*'+_nkw, Name.Constant),
            (r'[a-z_][a-zA-Z0-9_\']*'+_nkw, Name),
            (r'@[a-z_][a-zA-Z0-9_\']*'+_nkw, Name.Variable.Instance),
            (r'@@[a-z_][a-zA-Z0-9_\']*'+_nkw, Name.Variable.Class),
            (r'\(',                     Punctuation),
            (r'\)',                     Punctuation),
            (r'\[',                     Punctuation),
            (r'\]',                     Punctuation),
            (r'\{',                     Punctuation),
            (r'\}',                     right_angle_bracket),
            (r';',                      Punctuation),
            (r',',                      Punctuation),
            (r'<<=',                    Operator),
            (r'>>=',                    Operator),
            (r'<<',                     Operator),
            (r'>>',                     Operator),
            (r'==',                     Operator),
            (r'!=',                     Operator),
            (r'=>',                     Operator),
            (r'=',                      Operator),
            (r'<=>',                    Operator),
            (r'<=',                     Operator),
            (r'>=',                     Operator),
            (r'<',                      Operator),
            (r'>',                      Operator),
            (r'\+\+',                   Operator),
            (r'\+=',                    Operator),
            (r'-=',                     Operator),
            (r'\*\*=',                  Operator),
            (r'\*=',                    Operator),
            (r'\*\*',                   Operator),
            (r'\*',                     Operator),
            (r'/=',                     Operator),
            (r'\+',                     Operator),
            (r'-',                      Operator),
            (r'/',                      Operator),
            (r'%=',                     Operator),
            (r'%',                      Operator),
            (r'^=',                     Operator),
            (r'&&=',                    Operator),
            (r'&=',                     Operator),
            (r'&&',                     Operator),
            (r'&',                      Operator),
            (r'\|\|=',                  Operator),
            (r'\|=',                    Operator),
            (r'\|\|',                   Operator),
            (r'\|',                     Operator),
            (r'!',                      Operator),
            (r'\.\.\.',                 Operator),
            (r'\.\.',                   Operator),
            (r'\.',                     Operator),
            (r'::',                     Operator),
            (r':',                      Operator),
            (r'(\s|\n)+',               Whitespace),
            (r'[a-z_][a-zA-Z0-9_\']*',  Name.Variable),
        ],
    }

class SlashLexer(DelegatingLexer):
    """
    Lexer for the Slash programming language.
    """

    name = 'Slash'
    aliases = ['slash']
    filenames = ['*.sl']

    def __init__(self, **options):
        from pygments.lexers.web import HtmlLexer
        super(SlashLexer, self).__init__(HtmlLexer, SlashLanguageLexer, **options)

