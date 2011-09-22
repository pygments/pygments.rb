require 'rubypython'

module Pygments
  module FFI
    extend self

    def start(pygments_path = File.expand_path('../../../vendor/pygments-main/', __FILE__))
      RubyPython.start
      RubyPython.import('pkg_resources') rescue nil
      sys = RubyPython.import('sys')
      sys.path.insert(0, pygments_path)

      @modules = [ :lexers, :formatters, :styles, :filters ].inject(Hash.new) do |hash, name|
        hash[name] = RubyPython.import("pygments.#{name}")
        hash
      end

      @pygments = RubyPython.import('pygments')
    end

    def stop
      RubyPython.stop
      @pygments = nil
      @modules = {}
    end

    def formatters
      start unless pygments
      @modules[:formatters].get_all_formatters.to_enum.inject(Hash.new) do |hash, fmt|
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
      @modules[:lexers].get_all_lexers.to_enum.inject(Hash.new) do |hash, lxr|
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
      @modules[:filters].get_all_filters.to_enum.map{ |o| o.rubify }
    end

    def styles
      start unless pygments
      @modules[:styles].get_all_styles.to_enum.map{ |o| o.rubify }
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

      if code.nil? or code.empty?
        return code
      end

      opts[:options] ||= {}
      opts[:options][:outencoding] ||= 'utf-8'

      lexer = lexer_for(code, opts)

      kwargs = opts[:options] || {}
      fmt_name = (opts[:formatter] || 'html').downcase
      formatter = formatter_for(fmt_name, kwargs)

      out = pygments.highlight(code, lexer, formatter)
      str = out.rubify

      # ruby's GC will clean these up eventually, but we explicitly
      # decref to avoid unncessary memory/gc pressure.
      [ lexer, formatter, out ].each do |obj|
        obj.pObject.xDecref
      end

      str.force_encoding(opts[:options][:outencoding]) if str.respond_to?(:force_encoding)
      if fmt_name == 'html'
        str.gsub!(%r{</pre></div>\Z}, "</pre>\n</div>")
      end

      str
    end

    private

    attr_reader :pygments

    def formatter_for(name, opts={})
      start unless pygments
      @modules[:formatters].get_formatter_by_name!(name, opts)
    end

    def lexer_for(code, opts={})
      start unless pygments

      if code.is_a?(Hash)
        opts = code
        code = nil
      end

      mod = @modules[:lexers]
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
