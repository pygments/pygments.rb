$:.unshift('lib')

require 'benchmark'
require 'pygments/c'
require 'pygments/ffi'
require 'rubygems'
require 'albino'

num = ARGV[0] ? ARGV[0].to_i : 25
code = File.read(__FILE__)

albino, pygments, ffi =
  Albino.new(code, :ruby, :html).colorize,
  Pygments::C.highlight(code, :lexer => 'ruby'),
  Pygments::FFI.highlight(code, :lexer => 'ruby')

unless albino == pygments and pygments == ffi
  raise "incompatible implementations (#{albino.size} != #{pygments.size} != #{ffi.size})"
end

Benchmark.bm(25) do |x|
  x.report('albino') do
    num.times do
      Albino.new(code, :ruby, :html).colorize
    end
  end
  x.report('pygments::c') do
    num.times do
      Pygments::C.highlight(code, :lexer => 'ruby')
    end
  end
  x.report('pygments::ffi + reload') do
    num.times do
      Pygments::FFI.start
      Pygments::FFI.highlight(code, :lexer => 'ruby')
      Pygments::FFI.stop
    end
  end
  Pygments::FFI.start
  x.report('pygments::ffi') do
    num.times do
      Pygments::FFI.highlight(code, :lexer => 'ruby')
    end
  end
end

__END__

$ ruby -rubygems bench.rb 50
                               user     system      total        real
albino                     0.050000   0.050000  12.830000 ( 13.180806)
pygments::c                1.000000   0.010000   1.010000 (  1.009348)
pygments::ffi + reload    11.350000   1.240000  12.590000 ( 12.692320)
pygments::ffi              1.130000   0.010000   1.140000 (  1.171589)

