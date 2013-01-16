require File.join(File.dirname(__FILE__), 'pygments/popen')


module Pygments
  class << self
    attr_accessor :python_path
  end

  if RUBY_PLATFORM =~ /mswin|mingw/
    @python_path = "python"
  else
    @python_path = "/usr/bin/python"
  end

  extend Pygments::Popen

  autoload :Lexer, 'pygments/lexer'
end
