module Pygments
  class Lexer < Struct.new(:name, :aliases, :filenames, :mimetypes)
    @lexers          = []
    @index           = {}
    @name_index      = {}
    @alias_index     = {}
    @extname_index   = {}
    @mimetypes_index = {}

    # Internal: Create a new Lexer object
    #
    # hash - A hash of attributes
    #
    # Returns a Lexer object
    def self.create(hash)
      lexer = new(hash[:name], hash[:aliases], hash[:filenames], hash[:mimetypes])

      @lexers << lexer

      @index[lexer.name.downcase] = @name_index[lexer.name] = lexer

      lexer.aliases.each do |name|
        @alias_index[name] = lexer
        @index[name.downcase] ||= lexer
      end

      lexer.filenames.each do |filename|
        extnames = []

        extname = File.extname(filename)
        if m = extname.match(/\[(.+)\]/)
          m[1].scan(/./).each do |s|
            extnames << extname.sub(m[0], s)
          end
        elsif extname != ""
          extnames << extname
        end

        extnames.each do |extname|
          @extname_index[extname] = lexer
          @index[extname.downcase.sub(/^\./, "")] ||= lexer
        end
      end

      lexer.mimetypes.each do |type|
        @mimetypes_index[type] = lexer
      end

      lexer
    end

    # Public: Get all Lexers
    #
    # Returns an Array of Lexers
    def self.all
      @lexers
    end

    # Public: Look up Lexer by name or alias.
    #
    # name - A String name or alias
    #
    #   Lexer.find('Ruby')
    #   => #<Lexer name="Ruby">
    #
    # Returns the Lexer or nil if none was found.
    def self.find(name)
      @index[name.to_s.downcase]
    end

    # Public: Alias for find.
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
    # Returns the Lexer or nil if none was found.
    def self.find_by_name(name)
      @name_index[name]
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
    # Returns the Lexer or nil if none was found.
    def self.find_by_alias(name)
      @alias_index[name]
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
    # Returns the Lexer or nil if none was found.
    def self.find_by_extname(extname)
      @extname_index[extname]
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
    # Returns the Lexer or nil if none was found.
    def self.find_by_mimetype(type)
      @mimetypes_index[type]
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

    alias_method :==, :equal?
    alias_method :eql?, :equal?
  end

  lexers.values.each { |h| Lexer.create(h) }
end
