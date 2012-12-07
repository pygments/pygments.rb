# pygments.rb

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

- Python 2.5, Python 2.6, or Python 2.7. You can always use Python 2.x from a `virtualenv` if
  your default Python install is 3.x.

## usage

``` ruby 
require 'pygments'
``` 

``` ruby
Pygments.highlight(File.read(__FILE__), :lexer => 'ruby')
```

Encoding and other lexer/formatter options can be passed in via an
options hash:

``` ruby
Pygments.highlight('code', :options => {:encoding => 'utf-8'})
```

pygments.rb defaults to using an HTML formatter. 
To use a formatter other than `html`, specify it explicitly
like so:

``` ruby
Pygments.highlight('code', :formatter => 'bbcode')
Pygments.highlight('code', :formatter => 'terminal')
```

To generate CSS for HTML formatted code, use the `#css` method:

``` ruby
Pygments.css
Pygments.css('.highlight')
```

Other Pygments high-level API methods are also available.
These methods return arrays detailing all the available lexers, formatters, 
and styles.

``` ruby
Pygments.lexers
Pygments.formatters
Pygments.styles
```

To use a custom pygments installation, specify the path to
`Pygments#start`:

``` ruby
Pygments.start("/path/to/pygments")
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



