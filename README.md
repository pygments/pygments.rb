# pygments.rb [![GitHub Actions][gh-actions_badge]][gh-actions_url] [![Gem Version][gem_badge]][gem_url]

[gh-actions_badge]: https://github.com/tmm1/pygments.rb/workflows/CI/badge.svg?branch=master
[gh-actions_url]: https://github.com/tmm1/pygments.rb/actions?query=branch%3Amaster
[gem_badge]: https://img.shields.io/gem/v/pygments.rb.svg
[gem_url]: https://rubygems.org/gems/pygments.rb

A Ruby wrapper for the Python [pygments syntax highlighter](http://pygments.org/).

pygments.rb works by talking over a simple pipe to a long-lived
Python child process. This library replaces [github/albino](https://github.com/github/albino),
as well as a version of pygments.rb that used an embedded Python
interpreter.

Each Ruby process that runs has its own 'personal Python';
for example, 4 Unicorn workers will have one Python process each.
If a Python process dies, a new one will be spawned on the next
pygments.rb request.

## system requirements

- Python >= 3.5.
You can always install it using `virtualenv` if your default Python installation is 2.x.

## usage

```ruby
require 'pygments'
```

```ruby
Pygments.highlight(File.read(__FILE__), lexer: 'ruby')
```

Encoding and other lexer/formatter options can be passed in via an
options hash:

```ruby
Pygments.highlight('code', options: {encoding: 'utf-8'})
```

pygments.rb defaults to using an HTML formatter.
To use a formatter other than `html`, specify it explicitly
like so:

```ruby
Pygments.highlight('code', formatter: 'bbcode')
Pygments.highlight('code', formatter: 'terminal')
```

To generate CSS for HTML formatted code, use the `#css` method:

```ruby
Pygments.css
Pygments.css('.highlight')
```

To use a specific pygments style, pass the `:style` option to the `#css` method:

```ruby
Pygments.css(style: "monokai")
```

Other Pygments high-level API methods are also available.
These methods return arrays detailing all the available lexers, formatters,
and styles.

```ruby
Pygments.lexers
Pygments.formatters
Pygments.styles
```

To use a custom pygments installation, specify the path to
`Pygments#start`:

```ruby
Pygments.start("/path/to/pygments")
```

If you'd like logging, set the environmental variable `MENTOS_LOG` to a file path for your logfile.

You can apply a timeout to pygments.rb calls by specifying number of seconds in `MENTOS_TIMEOUT` environmental variable or by passing the `:timeout` argument (takes precedence over `MENTOS_TIMEOUT`):

```ruby
Pygments.highlight('code', timeout: 4)
```

## benchmarks


    $ ruby bench.rb 50
       Benchmarking....
       Size: 698 bytes
       Iterations: 50
                                                      user     system      total        real
       pygments popen                                0.010000   0.010000   0.020000 (  0.460370)
       pygments popen (process already started)      0.010000   0.000000   0.010000 (  0.272975)
       pygments popen (process already started 2)    0.000000   0.000000   0.000000 (  0.273589)

    $ ruby bench.rb 10
       Benchmarking....
       Size: 15523 bytes
       Iterations: 10
                                                      user     system      total        real
       pygments popen                               0.000000   0.000000   0.000000 (  0.819419)
       pygments popen (process already started)     0.010000   0.000000   0.010000 (  0.676515)
       pygments popen (process already started 2)   0.000000   0.010000   0.010000 (  0.674189)

## license

The MIT License (MIT)

Copyright (c) Ted Nyman and Aman Gupta, 2012-2013

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
