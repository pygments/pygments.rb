# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '/lib/pygments.rb')
require 'benchmark'

include Benchmark
# number of iterations
num = ARGV[0] ? ARGV[0].to_i : 10

# we can also repeat the code itself
repeats = ARGV[1] ? ARGV[1].to_i : 1

code = File.open('test/test_data.py').read.to_s * repeats

puts "Benchmarking....\n"
puts 'Size: ' + code.bytesize.to_s + " bytes\n"
puts 'Iterations: ' + num.to_s + "\n"

Benchmark.bm(40) do |x|
  x.report('pygments popen                             ')  { (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); } }
  x.report('pygments popen (process already started)   ')  { (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); } }
  x.report('pygments popen (process already started 2) ')  { (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); } }
end
