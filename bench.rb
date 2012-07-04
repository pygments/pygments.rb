require File.join(File.dirname(__FILE__), '/lib/pygments.rb')
require 'benchmark'

include Benchmark
# number of iterations
num = ARGV[0] ? ARGV[0].to_i : 25

# we can also repeat the code itself
repeats = ARGV[1] ? ARGV[1].to_i : 1

code = File.open('test/test_data.py').read.to_s * repeats

puts "Benchmarking....\n"
puts "Size: " + code.bytesize.to_s + " bytes\n"
puts "Iterations: " + num.to_s + "\n"

Benchmark.bm(40) do |x|
  x.report("pygments popen                             ")  { for i in 1..num; Pygments.highlight(code, :lexer => 'ruby'); end }
  x.report("pygments popen (process already started)   ")  { for i in 1..num; Pygments.highlight(code, :lexer => 'ruby'); end }
  x.report("pygments popen (process already started 2) ")  { for i in 1..num; Pygments.highlight(code, :lexer => 'ruby'); end }
end

# $ ruby bench.rb 50
#     Benchmarking....
#     Size: 698 bytes
#     Iterations: 50
#                                                     user     system      total        real
#     pygments popen                                0.010000   0.010000   0.020000 (  0.460370)
#     pygments popen (process already started)      0.010000   0.000000   0.010000 (  0.272975)
#     pygments popen (process already started 2)    0.000000   0.000000   0.000000 (  0.273589)
#
# $ ruby bench.rb 10
#     Benchmarking....
#     Size: 15523 bytes
#     Iterations: 10
#                                                    user     system      total        real
#     pygments popen                               0.000000   0.000000   0.000000 (  0.819419)
#     pygments popen (process already started)     0.010000   0.000000   0.010000 (  0.676515)
#     pygments popen (process already started 2)   0.000000   0.010000   0.010000 (  0.674189)
#
#
#
#
