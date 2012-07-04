require File.join(File.dirname(__FILE__), 'pygments/popen')


module Pygments
  extend Pygments::Popen

  autoload :Lexer, 'pygments/lexer'
end
