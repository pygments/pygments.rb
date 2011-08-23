module Pygments
  module C
    extend self

    def start(python_path = File.expand_path('../../../vendor/pygments-main/', __FILE__))
      ENV['PYTHONPATH'], prev = python_path, ENV['PYTHONPATH']
      require 'pygments_ext'
      @started = true
    ensure
      ENV['PYTHONPATH'] = prev
    end

    def stop
    end

    def formatters
      start unless @started

      _formatters.inject(Hash.new) do |hash, (name, desc, aliases)|
        name.sub!(/Formatter$/,'')
        hash[name] = {
          :name => name,
          :description => desc,
          :aliases => aliases
        }
        hash
      end
    end

    def lexers
      start unless @started

      _lexers.inject(Hash.new) do |hash, (name, aliases, files, mimes)|
        hash[name] = {
          :description => name,
          :aliases => aliases,
          :filenames => files,
          :mimetypes => mimes
        }
        hash
      end
    end

    def highlight(code, opts={})
      start unless @started

      out = _highlight(code, opts)
      if opts[:formatter].nil? or opts[:formatter].to_s.downcase == 'html'
        out.gsub!(%r{</pre></div>\Z}, "</pre>\n</div>")
      end
      out
    end
  end
end
