require 'pygments_ext'

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
  end
end
