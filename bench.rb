$:.unshift('lib')

require 'benchmark'
require 'pygments/c'
require 'pygments/ffi'
require 'rubygems'
require 'albino'

num = ARGV[0] ? ARGV[0].to_i : 25
code = File.read(__FILE__)

albino, pygments, ffi =
  Albino.new(code, :ruby, :html).execute.out,
  Pygments::C.highlight(code, :lexer => 'ruby'),
  Pygments::FFI.highlight(code, :lexer => 'ruby')

unless albino == pygments and pygments == ffi
  raise "incompatible implementations (#{albino.size} != #{pygments.size} != #{ffi.size})"
end

Benchmark.bm(25) do |x|
  x.report('albino') do
    num.times do
      Albino.new(code, :ruby, :html).execute.out
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

$ ruby bench.rb 50
                               user     system      total        real
albino                     0.040000   0.040000  12.930000 ( 13.609393)
pygments::c                1.000000   0.010000   1.010000 (  1.019455)
pygments::ffi + reload    11.720000   1.320000  13.040000 ( 13.339369)
pygments::ffi              1.120000   0.010000   1.130000 (  1.236264)
