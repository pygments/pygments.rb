require 'rubypython'

module Pygments
  module FFI
    extend self

    def start
      RubyPython.start

      %w[ pygments.lexers
          pygments.formatters
          pygments.styles
          pygments.filters ].each do |name|
        RubyPython.import(name)
      end

      @pygments = RubyPython.import('pygments')
    end

    def stop
      RubyPython.stop
      @pygments = nil
    end

    def formatters
      start unless pygments
      pygments.formatters.get_all_formatters.to_enum.inject(Hash.new) do |hash, fmt|
        name = fmt.__name__.rubify.sub!(/Formatter$/,'')

        hash[name] = {
          :name => name,
          :description => fmt.name.rubify,
          :aliases => fmt.aliases.rubify
        }
        hash
      end
    end

    def lexers
      start unless pygments
      pygments.lexers.get_all_lexers.to_enum.inject(Hash.new) do |hash, lxr|
        lxr = lxr.rubify
        name = lxr.first

        hash[name] = {
          :name => name,
          :aliases => lxr[1],
          :filenames => lxr[2],
          :mimetypes => lxr[3]
        }
        hash
      end
    end

    def filters
      start unless pygments
      pygments.filters.get_all_filters.to_enum.map{ |o| o.rubify }
    end

    def styles
      start unless pygments
      pygments.styles.get_all_styles.to_enum.map{ |o| o.rubify }
    end

    def css(klass='', opts={})
      if klass.is_a?(Hash)
        opts = klass
        klass = ''
      end
      fmt = formatter_for('html', opts)
      fmt.get_style_defs(klass).rubify
    end

    def lexer_name_for(*args)
      lxr = lexer_for(*args)
      lxr.aliases[0].rubify if lxr
    end

    def highlight(code, opts={})
      start unless pygments

      code.force_encoding('utf-8') if code.respond_to?(:force_encoding)
      code = RubyPython::PyMain.unicode(code, 'utf-8')

      kwargs = opts[:options] || {}

      lexer = lexer_for(code, opts)
      formatter = formatter_for(opts[:formatter] || 'html', kwargs)

      out = pygments.highlight(code, lexer, formatter)
      out = out.encode('utf-8')
      out = out.rubify
    end

    private

    attr_reader :pygments

    def formatter_for(name, opts={})
      start unless pygments
      pygments.formatters.get_formatter_by_name!(name, opts)
    end

    def lexer_for(code, opts={})
      start unless pygments

      if code.is_a?(Hash)
        opts = code
        code = nil
      end

      mod = pygments.lexers
      kwargs = opts[:options] || {}

      if name = opts[:lexer]
        mod.get_lexer_by_name!(name, kwargs)

      elsif name = opts[:mimetype]
        mod.get_lexer_for_mimetype!(name, kwargs)

      elsif name = opts[:filename]
        if code
          mod.guess_lexer_for_filename!(name, code, kwargs)
        else
          mod.get_lexer_for_filename!(name, kwargs)
        end

      elsif code
        mod.guess_lexer!(code, kwargs)

      else
        nil
      end
    end
  end
end
