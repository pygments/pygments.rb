# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '/lib/pygments.rb')
require 'benchmark'

# number of iterations
num = ARGV[0] ? ARGV[0].to_i : 10

# we can also repeat the code itself
repeats = ARGV[1] ? ARGV[1].to_i : 1

code = File.open('test/test_pygments.rb').read.to_s * repeats

puts "Benchmarking....\n"
puts "Size: #{code.bytesize} bytes\n"
puts "Iterations: #{num}\n"

Benchmark.bm(40) do |x|
  x.report('pygments popen                             ') do
    (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); }
  end
  x.report('pygments popen (process already started)   ') do
    (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); }
  end
  x.report('pygments popen (process already started 2) ') do
    (1..num).each { |_i|; Pygments.highlight(code, lexer: 'python'); }
  end
end
