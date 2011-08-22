module Pygments
  class Lexer < Struct.new(:name, :aliases, :filenames, :mimetypes)
    def self.[](name)
      Pygments.lexers[name]
    end

    def highlight(text, options = {})
      options[:lexer] = aliases.first
      Pygments.highlight(text, options)
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      equal?(other)
    end
  end
end
