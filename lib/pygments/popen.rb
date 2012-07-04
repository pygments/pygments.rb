# coding: utf-8

require 'posix/spawn'
require 'yajl'

# Error class
class MentosError < IOError
end

module Pygments
  module Popen
    include POSIX::Spawn
    extend self

    # Get things started by opening a pipe to mentos (the freshmaker), a
    # Python process that talks to the Pygments library. We'll talk back and
    # forth across this pipe.
    #
    # The #start method also includes logic for dealing with signals from the
    # child.
    #
    def start(pygments_path = File.expand_path('../../../vendor/pygments-main/', __FILE__))
      ENV['PYGMENTS_PATH'] = pygments_path

      # Make sure we kill off the child when we're done
      at_exit { stop }

      # A pipe to the mentos python process. #POSIX::Spawn#popen4 gives us
      # the pid and three IO objects to write and read..
      @pid, @in, @out, @err = popen4(File.expand_path('../mentos.py', __FILE__))

      # Deal with dying child processes.
      Signal.trap('CHLD') do

        # Once waitpid() returns the pid (i.e., the child process exited),
        # we can safely set our pid variable to nil. Next time a Pygments.rb
        # method gets called, the child will be spawned again, so we don't
        # need to spawn a new child in this block right now. For extra safety,
        # if an ECHILD (no children) is set by waitpid(), don't die horribly;
        # still set the @pid to nil.
        begin
          @pid = nil if Process.waitpid == @pid
        rescue Errno::ECHILD
          @pid = nil
        end
      end
    end

    # Stop the child process by issuing a brutal kill.
    # We call waitpid() with the pid, which waits for that particular
    # child.
    #
    # kill() can set errno to ESRCH if, for some reason, the file
    # is gone; regardless the final outcome of this method
    # will be to set our @pid variable to nil.
    #
    # Technically, kill() can also fail with EPERM or EINVAL (wherein
    # the signal isn't sent); but we have permissions, and
    # we're not doing anything invalid here.
    #
    def stop
      if @pid
        begin
          Process.kill('KILL', @pid)
          Process.waitpid(@pid)
        rescue Errno::ESRCH
        end
      end

      @pid = nil
    end

    # Check for a @pid variable, and then hit `kill -0` with the pid to
    # check if the pid is still in the process table. If this function
    # gives us an ENOENT or ESRCH, we can also safely return false (no process
    # to worry about).
    #
    # Returns true if the child is alive.
    def alive?
      return true if @pid && Process.kill(0, @pid)
      false
    rescue Errno::ENOENT, Errno::ESRCH
      false
    end

    # Public: Get an array of available Pygments formatters
    #
    # Returns an array of formatters.
    def formatters
      mentos(:get_all_formatters).inject(Hash.new) do | hash, (name, desc, aliases) |
        # Remove the long-winded and repetitive 'Formatter' suffix
        name.sub!(/Formatter$/, '')
        hash[name] = {
          :name => name,
          :description => desc,
          :aliases => aliases
        }
        hash
      end
    end

    # Public: Get back all available lexers
    #
    # Returns an array of lexers
    def lexers
      mentos(:get_all_lexers).inject(Hash.new) do |hash, lxr|
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

    # Public: Return an array of all available filters
    #
    def filters
      mentos(:get_all_filters)
    end

    # Public: Return an array of all available styles
    def styles
      mentos(:get_all_styles)
    end

    # Public: Return css for highlighted code
    def css(klass='', opts={})
      if klass.is_a?(Hash)
        opts = klass
        klass = ''
      end
      mentos(:css, ['html', klass], opts)
    end

    # Public: Return the name of a lexer.
    def lexer_name_for(*args)
      # Pop off the last arg if it's a hash, which becomes our opts
      if args.last.is_a?(Hash)
        opts = args.pop
      else
        opts = {}
      end

      mentos(:lexer_name_for, args, opts)
    end

    # Public: Highlight code.
    #
    # Our most important method. Takes a first-position argument of
    # the code to be highlighted, and a second-position hash of various
    # arguments specifiying highlighting properties.
    #
    # The code will be passed along to mentos as one of the 'args'
    # in the standard 'rpc' call.
    #
    def highlight(code, opts={})
      # If the caller didn't give us any code, we have nothing to do,
      # so return right away.
      return code if code.nil? or code.empty?

      # Callers pass along options in the hash
      opts[:options] ||= {}

      # Default to utf-8 for the output encoding, if not given.
      opts[:options][:outencoding] ||= 'utf-8'

      # Get back the string from mentos and force encoding if we can
      str = mentos(:highlight, code, opts, code)
      str.force_encoding(opts[:options][:outencoding]) if str.respond_to?(:force_encoding)
      str
    end

    private

    # Our 'rpc'-ish request to mentos. Requires a method name, and then optional
    # args, kwargs, code.
    def mentos(method, args=[], kwargs={}, code=nil)

      # Open the pipe if necessary
      start unless alive?

      # Of utmost importance, we need to send over the total number of bytes,
      # including newline, that we're sending to be highlighted, allowing mentos to
      # do its work properly.
      kwargs.merge!("bytes" => code.size + 1) if code

      # Send the fd over for logging purposes
      kwargs.merge!("fd" => @out.to_i)

      # This magic moment: we send the request through the pipe. If there's text/code
      # to be highlighted, we send that after.
      req = Yajl.dump(:method => method, :args => args, :kwargs => kwargs)
      @in.puts(req)
      @in.puts(code) if code

      # Get the response header
      header = @out.gets
      if header
        # The header comes in as JSON
        header = Yajl.load(header)
        bytes = header["bytes"]

        # Read more bytes (the actual response body)
        res = @out.read(bytes.to_i)

        # This is hackish but works. Open to suggestions.
        if res == "Bad header/no data"
          res = nil
        end

        # Some methods want arrays from json. Other methods just want us to return
        # the text (like highlighting), in which case we just pass the res right on through.
        if res
          res = Yajl.load(res, :symbolize_keys => true) unless code || method == :lexer_name_for || method == :css
          res = res.strip if code || method == :lexer_name_for || method == :css
          res
        end
      end
    end

    rescue Errno::EPIPE, EOFError
    # Pipe error or end-of-file error, raise
    raise IOException.new
  end
end

