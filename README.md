# pygments.rb

a ruby wrapper for the pygments syntax highlighter via embedded python.

    $ ruby -rubygems bench.rb 50
                                   user     system      total        real
    albino                     0.050000   0.050000  12.830000 ( 13.180806)
    pygments::c                1.000000   0.010000   1.010000 (  1.009348)
    pygments::ffi + reload    11.350000   1.240000  12.590000 ( 12.692320)
    pygments::ffi              1.130000   0.010000   1.140000 (  1.171589)

