# require 'pygments/c'
require 'pygments/ffi'

module Pygments
  # include Pygments::C
  include Pygments::FFI

  autoload :Lexer, 'pygments/lexer'

  extend self
end
