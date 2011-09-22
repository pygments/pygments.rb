# pygments.rb

A ruby wrapper for the python [pygments syntax highlighter](http://pygments.org/).

This library replaces [github/albino](https://github.com/github/albino).
Instead of shelling out to `pygmentize`, it embeds the python
interpreter inside ruby via FFI. This avoids the cost of setting up the
python VM on every invocation and speeds up code highlighting from ruby by 10-15x.

## usage

``` ruby
Pygments.highlight(File.read(__FILE__), :lexer => 'ruby')
```

Encoding and other lexer/formatter options can be passed in via an
options hash:

``` ruby
Pygments.highlight('code', :options => {:encoding => 'utf-8'})
```

To use a formatter other than html, specify it explicitly:

``` ruby
Pygments.highlight('code', :formatter => 'bbcode')
Pygments.highlight('code', :formatter => 'terminal')
```

To generate CSS for html formatted code, use the css method:

``` ruby
Pygments.css
Pygments.css('.highlight')
```

To use a custom python installation (like in ArchLinux), tell
RubyPython where python lives:

``` ruby
RubyPython.configure :python_exe => 'python2.7'
```

To use a custom pygments installation, specify the path to
Pygments.start:

``` ruby
Pygments.start("/path/to/pygments")
```

## benchmarks

    $ ruby -rubygems bench.rb 50
                                   user     system      total        real
    albino                     0.050000   0.050000  12.830000 ( 13.180806)
    pygments::c                1.000000   0.010000   1.010000 (  1.009348)
    pygments::ffi + reload    11.350000   1.240000  12.590000 ( 12.692320)
    pygments::ffi              1.130000   0.010000   1.140000 (  1.171589)

To run `bench.rb`, use a git checkout. The C extension is not included
in gem releases.
