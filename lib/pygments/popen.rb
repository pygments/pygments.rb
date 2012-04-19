require 'posix/spawn'
require 'yajl'

module Pygments
  module Popen
    include POSIX::Spawn
    extend self

    def start(pygments_path = File.expand_path('../../../vendor/pygments-main/', __FILE__))
      ENV['PYGMENTS_PATH'] = pygments_path
      at_exit{ stop }
      @pid, @in, @out, @err = popen4(File.expand_path('../popen.py', __FILE__))
    end

    def stop
      if @pid
        begin
          Process.kill 'KILL', @pid
          Process.waitpid @pid
        rescue Errno::ESRCH
        end
      end

      @pid = nil
    end

    def alive?
      return true if @pid && Process.kill(0, @pid)
      false
    rescue Errno::ENOENT, Errno::ESRCH
      false
    end

    def formatters
      rpc(:get_all_formatters).inject(Hash.new) do |hash, (name, desc, aliases)|
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
      rpc(:get_all_lexers).inject(Hash.new) do |hash, lxr|
        name = lxr[0]
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
      rpc(:get_all_filters)
    end

    def styles
      rpc(:get_all_styles)
    end

    def css(klass='', opts={})
      if klass.is_a?(Hash)
        opts = klass
        klass = ''
      end
      rpc(:css, ['html', klass], opts)
    end

    def lexer_name_for(*args)
      opts = args.pop if args.last.is_a?(Hash)
      rpc(:lexer_name_for, args, opts)
    end

    def highlight(code, opts={})
      if code.nil? or code.empty?
        return code
      end

      opts[:options] ||= {}
      opts[:options][:outencoding] ||= 'utf-8'

      str = rpc(:highlight, code, opts)
      str.force_encoding(opts[:options][:outencoding]) if str.respond_to?(:force_encoding)
      str
    end

    private

    def rpc(method, args=nil, kwargs=nil)
      start unless alive?

      req = Yajl.dump(:method => method, :args => args, :kwargs => kwargs)
      # use select/read+write loop (copy posix-spawn)
      @in.puts(req)
      if res = @out.gets and res.any?
        res = Yajl.load(res, :symbolize_keys => true)
      else
        p @err.read
        res = nil
      end

      res
    rescue Errno::EPIPE, EOFError
      p $!
      # retry
      raise
    end
  end
end
