# frozen_string_literal: true

require 'json'
require 'open3'
require 'logger'
require 'time'

# Error class
class MentosError < IOError
end

# Pygments provides access to the Pygments library via a pipe and a long-running
# Python process.
module Pygments
  class Popen
    # Get things started by opening a pipe to mentos (the freshmaker), a
    # Python process that talks to the Pygments library. We'll talk back and
    # forth across this pipe.
    def start(pygments_path = File.join(__dir__, '..', '..', 'vendor', 'pygments-main'))
      @log = Logger.new(ENV['MENTOS_LOG'] || File::NULL)
      @log.level = Logger::INFO
      @log.datetime_format = '%Y-%m-%d %H:%M '

      ENV['PYGMENTS_PATH'] = pygments_path

      # Make sure we kill off the child when we're done
      at_exit { stop 'Exiting' }

      # A pipe to the mentos python process. #popen4 gives us
      # the pid and three IO objects to write and read.
      argv = [*python_binary, File.join(__dir__, 'mentos.py')]
      @pid, @in, @out, @err = popen4(argv)
      @in.binmode
      @out.binmode
      @log.info "Starting pid #{@pid} with python #{python_binary}."
    end

    def python_binary
      @python_binary ||= find_python_binary
    end

    def python_binary=(python_bin)
      @python_bin = python_bin
    end

    # Stop the child process by issuing a kill -9.
    #
    # We then call waitpid() with the pid, which waits for that particular
    # child and reaps it.
    #
    # kill() can set errno to ESRCH if, for some reason, the file
    # is gone; regardless the final outcome of this method
    # will be to set our @pid variable to nil.
    #
    # Technically, kill() can also fail with EPERM or EINVAL (wherein
    # the signal isn't sent); but we have permissions, and
    # we're not doing anything invalid here.
    # @param reason [String]
    def stop(reason)
      unless @pid.nil?
        @log.info "Killing pid: #{@pid}. Reason: #{reason}"
        begin
          Process.kill('KILL', @pid)
          Process.waitpid(@pid)
        rescue Errno::ESRCH, Errno::ECHILD => e
          @log.warn(e)
        end
      end
      @pid = nil
    end

    # Check for a @pid variable, and then hit `kill -0` with the pid to
    # check if the pid is still in the process table. If this function
    # gives us an ENOENT or ESRCH, we can also safely return false (no process
    # to worry about). Defensively, if EPERM is raised, in a odd/rare
    # dying process situation (e.g., mentos is checking on the pid of a dead
    # process and the pid has already been re-used) we'll want to raise
    # that as a more informative Mentos exception.
    #
    # @return [Boolean] true if the child is alive.
    def alive?
      return true if defined?(@pid) && @pid && Process.kill(0, @pid)

      false
    rescue Errno::ENOENT, Errno::ESRCH
      false
    rescue Errno::EPERM
      raise MentosError, 'EPERM checking if child process is alive.'
    end

    # Public: Returns version of underlying Pygments library
    #
    # @return [Integer]
    def pygments_version
      mentos(:version)[0]
    end

    # Public: Get an array of available Pygments formatters
    #
    # @return [Array<String>] an array of formatters
    def formatters
      mentos(:get_all_formatters).each_with_object({}) do |(name, desc, aliases), hash|
        # Remove the long-winded and repetitive 'Formatter' suffix
        name.sub!(/Formatter$/, '')
        hash[name] = {
          name: name,
          description: desc,
          aliases: aliases
        }
      end
    end

    # Get all available lexers from mentos itself
    # Do not use this method directly, instead use Pygments#lexers
    #
    # @return [Array<String>] an array of lexers
    def lexers!
      mentos(:get_all_lexers).each_with_object({}) do |lxr, hash|
        name = lxr[0]
        hash[name] = {
          name: name,
          aliases: lxr[1],
          filenames: lxr[2],
          mimetypes: lxr[3]
        }
      end
    end

    # @return [Array<String>] an array of all available filters
    def filters
      mentos(:get_all_filters)
    end

    # @return [Array<String>] an array of all available styles
    def styles
      mentos(:get_all_styles)
    end

    # @return [String] css for highlighted code
    def css(klass = '', opts = {})
      if klass.is_a?(Hash)
        opts = klass
        klass = ''
      end
      mentos(:css, ['html', klass], opts)
    end

    # @return [[String], nil] aliases of a lexer.
    def lexer_names_for(*args)
      # Pop off the last arg if it's a hash, which becomes our opts
      opts = if args.last.is_a?(Hash)
               args.pop
             else
               {}
             end

      code = (args.pop if args.last.is_a?(String))

      mentos(:lexer_names_for, args, opts, code)
    end

    # Public: Highlight code.
    #
    # Takes a first-position argument of the code to be highlighted,
    # and a second-position hash of various arguments specifying
    # highlighting properties.
    #
    # Returns the highlighted string
    # or nil when the request to the Python process timed out.
    def highlight(code, opts = {})
      # If the caller didn't give us any code, we have nothing to do,
      # so return right away.
      return code if code.nil? || code.empty?

      # Callers pass along options in the hash
      opts[:options] ||= {}

      # Default to utf-8 for the output encoding, if not given.
      opts[:options][:outencoding] ||= 'utf-8'

      # Get back the string from mentos and force encoding if we can
      str = mentos(:highlight, nil, opts, code)
      str.force_encoding(opts[:options][:outencoding]) if str.respond_to?(:force_encoding)
      str
    end

    private

    # @param argv [Array<String>]
    def popen4(argv)
      stdin, stdout, stderr, wait_thr = Open3.popen3(*argv, { close_others: true })
      while (pid = wait_thr.pid).nil? && wait_thr.alive?
        # wait_thr.pid is not immediately available on JRuby. Why???
      end
      [pid, stdin, stdout, stderr]
    end

    # Detect a suitable Python binary to use.
    def find_python_binary
      return %w[py python3 python].first { |py| !which(py).nil? } if Gem.win_platform?

      # On non-Windows platforms, we simply rely on shebang
      []
    end

    # Cross platform which command
    # from http://stackoverflow.com/a/5471032/284795
    def which(command)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |dir|
        exts.each do |ext|
          path = File.join(dir, "#{command}#{ext}")
          return path if File.executable?(path) && !File.directory?(path)
        end
      end
      nil
    end

    # @param timeout [Integer]
    # @param error_message [String]
    # @yield
    def with_watchdog(timeout, error_message)
      state_mutex = Mutex.new
      state = :alive
      wd_cleanup = ConditionVariable.new

      watchdog = if timeout.positive?
                   Thread.new do
                     state_mutex.synchronize do
                       wd_cleanup.wait(state_mutex, timeout) if state != :finished
                       if state != :finished
                         @log.error error_message
                         stop error_message
                         state = :timeout
                       end
                     end
                   end
                 end

      begin
        yield
      ensure
        if watchdog
          state_mutex.synchronize do
            state = :finished if state == :alive
            # wake up watchdog thread
            wd_cleanup.signal
          end
          watchdog.join
        end

        raise MentosError, error_message if state == :timeout
      end
    end

    # Our 'rpc'-ish request to mentos. Requires a method name, and then optional
    # args, kwargs, code.
    def mentos(method, args = [], kwargs = {}, code = nil)
      # Open the pipe if necessary
      start unless alive?

      # Add metadata to the header and generate it.
      kwargs = kwargs.merge('bytes' => (code.nil? ? 0 : code.bytesize))
      out_header = JSON.generate(method: method, args: args, kwargs: kwargs)

      begin
        timeout = get_timeout(kwargs.delete(:timeout))
        res = with_watchdog(timeout, "Timeout on a mentos #{method} call") do
          write_header(out_header, code)

          # mentos will now return data to us. First it sends the header.
          header_len_bytes = @out.read(4)
          if header_len_bytes.nil?
            raise Errno::EPIPE, %(Failed to read response from Python process on a mentos #{method} call)
          end

          header_len = header_len_bytes.unpack('N')[0]
          @log.info "Size in: #{header_len}"
          header = @out.read(header_len)

          # Now handle the header, any read any more data required.
          handle_header_and_return(header)
        end

        # Finally, return what we got.
        return_result(res, method)
      rescue Errno::EPIPE => e
        begin
          error_msg = @err.read
          @log.error "Error running Python script: #{error_msg}"
          stop "Error running Python script: #{error_msg}"
          raise MentosError, %(#{e}: #{error_msg})
        rescue Errno::EPIPE
          @log.error e.to_s
          stop e.to_s
          raise e
        end
      rescue StandardError => e
        @log.error e.to_s
        stop e.to_s
        raise e
      end
    end

    # @param header [String]
    # @param code [String, nil]
    def write_header(header, code)
      # Get the size of the header itself and write that.
      @in.write([header.bytesize].pack('N'))
      @log.info "Size out: #{header.bytesize}"

      # mentos is now waiting for the header, and, potentially, code.
      @in.write(header)
      @log.info "Out header: #{header}"
      @in.write(code) unless code.nil?
      @in.flush
    end

    # @param timeout [Integer, nil]
    # @return [Integer]
    def get_timeout(timeout)
      return timeout unless timeout.nil?

      begin
        Integer(ENV['MENTOS_TIMEOUT'])
      rescue TypeError
        0
      end
    end

    # Based on the header we receive, determine if we need
    # to read more bytes, and read those bytes if necessary.
    #
    # @param header [String, nil]
    # @return [String, nil] either highlighted text or metadata.
    def handle_header_and_return(header)
      raise MentosError, 'No header received back.' if header.nil?

      @log.info "In header: #{header}"
      header = header_to_json(header)
      bytes = header[:bytes]

      # Read more bytes (the actual response body)
      res = @out.read(bytes.to_i)

      if header[:method] == 'highlight' && res.nil?
        # Make sure we have a result back; else consider this an error.
        raise MentosError, 'No highlight result back from mentos.'
      end

      res
    end

    # @return Ruby objects for the methods that want them, text otherwise.
    def return_result(res, method)
      res = JSON.parse(res, symbolize_names: true) unless %i[highlight css].include?(method)
      res = res.rstrip if res.instance_of?(String)
      res
    end

    # Convert a text header into JSON for easy access.
    # @param header [String]
    # @return [JSON]
    def header_to_json(header)
      json = JSON.parse(header, symbolize_names: true)
      raise MentosError, json[:error] unless json[:error].nil?

      json
    end
  end
end
