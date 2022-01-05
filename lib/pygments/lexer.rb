# frozen_string_literal: true

require 'singleton'

module Pygments
  class Lexer < Struct.new(:name, :aliases, :filenames, :mimetypes)
    # Public: Get all Lexers
    #
    # @return [Array<Lexer>]
    def self.all
      LexerCache.instance.lexers
    end

    # Public: Look up Lexer by name or alias.
    #
    # name - A String name or alias
    #
    #   Lexer.find('Ruby')
    #   => #<Lexer name="Ruby">
    #
    # @return [Lexer, nil]
    def self.find(name)
      LexerCache.instance.index[name.to_s.downcase]
    end

    # Public: Alias for find.
    #
    # @param name [String]
    # @return [Lexer, nil]
    def self.[](name)
      find(name)
    end

    # Public: Look up Lexer by its proper name.
    #
    # name - The String name of the Lexer
    #
    # Examples
    #
    #   Lexer.find_by_name('Ruby')
    #   # => #<Lexer name="Ruby">
    #
    # @param name [String]
    # @return [Lexer, nil]
    def self.find_by_name(name)
      LexerCache.instance.name_index[name]
    end

    # Public: Look up Lexer by one of its aliases.
    #
    # name - A String alias of the Lexer
    #
    # Examples
    #
    #   Lexer.find_by_alias('rb')
    #   # => #<Lexer name="Ruby">
    #
    # @param name [String]
    # @return [Lexer, nil]
    def self.find_by_alias(name)
      LexerCache.instance.alias_index[name]
    end

    # Public: Look up Lexer by one of it's file extensions.
    #
    # extname - A String file extension.
    #
    # Examples
    #
    #  Lexer.find_by_extname('.rb')
    #  # => #<Lexer name="Ruby">
    #
    # @param extname [String]
    # @return [Lexer, nil]
    def self.find_by_extname(extname)
      LexerCache.instance.extname_index[extname]
    end

    # Public: Look up Lexer by one of it's mime types.
    #
    # type - A mime type String.
    #
    # Examples
    #
    #  Lexer.find_by_mimetype('application/x-ruby')
    #  # => #<Lexer name="Ruby">
    #
    # @param type [String]
    # @return [Lexer, nil]
    def self.find_by_mimetype(type)
      LexerCache.instance.mimetypes_index[type]
    end

    # Public: Highlight syntax of text
    #
    # text    - String of code to be highlighted
    # options - Hash of options (defaults to {})
    #
    # Returns html String
    def highlight(text, options = {})
      options[:lexer] = aliases.first
      Pygments.highlight(text, options)
    end

    alias == equal?
    alias eql? equal?
  end

  class LexerCache
    include Singleton

    # @return [Array<Lexer>]
    attr_reader(:lexers)
    # @return [Map<String, Lexer>]
    attr_reader(:index)
    # @return [Map<String, Lexer>]
    attr_reader(:name_index)
    # @return [Map<String, Lexer]
    attr_reader(:alias_index)
    # @return [Map<String, Lexer>]
    attr_reader(:extname_index)
    # @return [Map<String, Lexer>]
    attr_reader(:mimetypes_index)

    attr_reader(:raw_lexers)

    def initialize
      @lexers = []
      @index = {}
      @name_index = {}
      @alias_index = {}
      @extname_index = {}
      @mimetypes_index = {}
      @raw_lexers = Pygments.lexers!

      @raw_lexers.each_value do |hash|
        lexer = Lexer.new(hash[:name], hash[:aliases], hash[:filenames], hash[:mimetypes])

        @lexers << lexer

        @index[lexer.name.downcase] = @name_index[lexer.name] = lexer

        lexer.aliases.each do |name|
          @alias_index[name] = lexer
          @index[name.downcase] ||= lexer
        end

        lexer.filenames.each do |filename|
          extnames = []

          extname = File.extname(filename)
          if (m = extname.match(/\[(.+)\]/))
            m[1].scan(/./).each do |s|
              extnames << extname.sub(m[0], s)
            end
          elsif extname != ''
            extnames << extname
          end

          extnames.each do |the_extname|
            @extname_index[the_extname] = lexer
            @index[the_extname.downcase.sub(/^\./, '')] ||= lexer
          end
        end

        lexer.mimetypes.each do |type|
          @mimetypes_index[type] = lexer
        end
      end
    end
  end
end
