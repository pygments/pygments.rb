# require 'pygments/c'
# require 'pygments/ffi'
require 'pygments/popen'

module Pygments
  # extend Pygments::C
  # extend Pygments::FFI
  extend Pygments::Popen

  autoload :Lexer, 'pygments/lexer'
end
