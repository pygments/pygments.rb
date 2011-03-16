ENV['PYTHONPATH'] = File.expand_path('../../../vendor/Pygments-1.4/', __FILE__)
require 'pygments_ext'
ENV['PYTHONPATH'] = nil

module Pygments
  module C
    extend self

    def formatters
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
      out = _highlight(code, opts)
      if opts[:formatter].nil? or opts[:formatter].to_s.downcase == 'html'
        out.gsub!(%r{</pre></div>\Z}, "</pre>\n</div>")
      end
      out
    end
  end
end
