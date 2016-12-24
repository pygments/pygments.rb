# coding: utf-8
require 'open3'
require 'multi_json'
require 'timeout'
require 'logger'
require 'time'

# Error class
class MentosError < IOError
end

# Pygments provides access to the Pygments library via a pipe and a long-running
# Python process.
module Pygments
  class Popen

    def popen4(cmd)
      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
      [wait_thr[:pid], stdin, stdout, stderr]
    end

    # Get things started by opening a pipe to mentos (the freshmaker), a
    # Python process that talks to the Pygments library. We'll talk back and
    # forth across this pipe.
    def start(pygments_path = File.expand_path('../../../vendor/pygments-main/', __FILE__))
      begin
        @log = Logger.new(ENV['MENTOS_LOG'] ||= File::NULL)
        @log.level = Logger::INFO
        @log.datetime_format = "%Y-%m-%d %H:%M "
      rescue
        @log = Logger.new(File::NULL)
      end

      ENV['PYGMENTS_PATH'] = pygments_path

      # Make sure we kill off the child when we're done
      at_exit { stop "Exiting" }

      # A pipe to the mentos python process. #popen4 gives us
      # the pid and three IO objects to write and read.
      script = "#{python_binary} #{File.expand_path('../mentos.py', __FILE__)}"
      @pid, @in, @out, @err = popen4(script)
      @log.info "Starting pid #{@pid} with fd #{@out.to_i} and python #{python_binary}."
    end

    def windows?
      RUBY_PLATFORM =~ /mswin|mingw/
    end

    def python_binary
      @python_binary ||= find_python_binary
    end

    def python_binary=(python_bin)
      @python_bin = python_bin
    end

    # Detect a suitable Python binary to use.
    # Or return $PYGMENTS_RB_PYTHON if it's exists.
    def find_python_binary
      if ENV['PYGMENTS_RB_PYTHON']
        return which(ENV['PYGMENTS_RB_PYTHON'])
      elsif windows? && which('py')
        return 'py -2'
      end
      return which('python2') || which('python')
    end

    # Cross platform which command
    # from http://stackoverflow.com/a/5471032/284795
    def which(command)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |dir|
        exts.each { |ext|
          path = File.join(dir, "#{command}#{ext}")
          return path if File.executable?(path) && !File.directory?(path)
        }
      end
      return nil
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
    def stop(reason)
      if @pid
        begin
          Process.kill('KILL', @pid)
          Process.waitpid(@pid)
        rescue Errno::ESRCH, Errno::ECHILD
        end
      end
      @log.info "Killing pid: #{@pid.to_s}. Reason: #{reason}"
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
    # Returns true if the child is alive.
    def alive?
      return true if defined?(@pid) && @pid && Process.kill(0, @pid)
      false
    rescue Errno::ENOENT, Errno::ESRCH
      false
    rescue Errno::EPERM
      raise MentosError, "EPERM checking if child process is alive."
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


    # Public: Get all lexers from a serialized array. This avoids needing to spawn
    # mentos when it's not really needed (e.g., one-off jobs, loading the Rails env, etc).
    #
    # Should be preferred to #lexers!
    #
    # Returns an array of lexers.
    def lexers
      begin
        lexer_file = File.expand_path('../../../lexers', __FILE__)
        raw = File.open(lexer_file, "rb").read
        Marshal.load(raw)
      rescue Errno::ENOENT
        raise MentosError, "Error loading lexer file. Was it created and vendored?"
      end
    end

    # Public: Get back all available lexers from mentos itself
    #
    # Returns an array of lexers.
    def lexers!
      mentos(:get_all_lexers).inject(Hash.new) do |hash, lxr|
        name = lxr[0]
        hash[name] = {
          :name => name,
          :aliases => lxr[1],
          :filenames => lxr[2],
          :mimetypes => lxr[3]
        }
        hash["dasm16"] = {:name=>"dasm16", :aliases=>["DASM16"], :filenames=>["*.dasm16", "*.dasm"], :mimetypes=>['text/x-dasm16']}
        hash["Puppet"] = {:name=>"Puppet", :aliases=>["puppet"], :filenames=>["*.pp"], :mimetypes=>[]}
        hash["Augeas"] = {:name=>"Augeas", :aliases=>["augeas"], :filenames=>["*.aug"], :mimetypes=>[]}
        hash["TOML"]   = {:name=>"TOML",   :aliases=>["toml"],   :filenames=>["*.toml"], :mimetypes=>[]}
        hash["Slash"]  = {:name=>"Slash",  :aliases=>["slash"],  :filenames=>["*.sl"], :mimetypes=>[]}
        hash
      end
    end

    # Public: Return an array of all available filters
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

      if args.last.is_a?(String)
        code = args.pop
      else
        code = nil
      end

      mentos(:lexer_name_for, args, opts, code)
    end

    # Public: Highlight code.
    #
    # Takes a first-position argument of the code to be highlighted, and a
    # second-position hash of various arguments specifying highlighting properties.
    #
    # Returns the highlighted string
    # or nil when the request to the Python process timed out.
    def highlight(code, opts={})
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

    # Our 'rpc'-ish request to mentos. Requires a method name, and then optional
    # args, kwargs, code.
    def mentos(method, args=[], kwargs={}, original_code=nil)
      # Open the pipe if necessary
      start unless alive?

      begin
        # Timeout requests that take too long.
        # Invalid MENTOS_TIMEOUT results in just using default.
        timeout_time = Integer(ENV["MENTOS_TIMEOUT"]) rescue 8

        Timeout::timeout(timeout_time) do
          # For sanity checking on both sides of the pipe when highlighting, we prepend and
          # append an id.  mentos checks that these are 8 character ids and that they match.
          # It then returns the id's back to Rubyland.
          id = (0...8).map{65.+(rand(25)).chr}.join
          code = add_ids(original_code, id) if original_code

          # Add metadata to the header and generate it.
          if code
            bytesize = code.bytesize
          else
            bytesize = 0
          end

          kwargs.freeze
          kwargs = kwargs.merge("fd" => @out.to_i, "id" => id, "bytes" => bytesize)
          out_header = MultiJson.dump(:method => method, :args => args, :kwargs => kwargs)

          # Get the size of the header itself and write that.
          bits = get_fixed_bits_from_header(out_header)
          @in.write(bits)

          # mentos is now waiting for the header, and, potentially, code.
          write_data(out_header, code)

          check_for_error

          # mentos will now return data to us. First it sends the header.
          header = get_header

          # Now handle the header, any read any more data required.
          res = handle_header_and_return(header, id)

          # Finally, return what we got.
          return_result(res, method)
        end
      rescue Timeout::Error
        # If we timeout, we need to clear out the pipe and start over.
        @log.error "Timeout on a mentos #{method} call"
        stop "Timeout on mentos #{method} call."
      end

    rescue Errno::EPIPE, EOFError
    stop "EPIPE"
    raise MentosError, "EPIPE"
    end

    def check_for_error
      return if @err.closed?

      timeout_time = 0.25 # set a very little timeout so that we do not hang the parser

      Timeout::timeout(timeout_time) do
        error_msg = @err.read

        unless error_msg.empty?
          @log.error "Error running python script: #{error_msg}"
          stop "Error running python script: #{error_msg}"
          raise MentosError, error_msg
        end
      end
    rescue Timeout::Error
      # during the specified time no error were found
      @err.close
    end


    # Based on the header we receive, determine if we need
    # to read more bytes, and read those bytes if necessary.
    #
    # Then, do a sanity check with the ids.
    #
    # Returns a result — either highlighted text or metadata.
    def handle_header_and_return(header, id)
      if header
        header = header_to_json(header)
        bytes = header[:bytes]

        # Read more bytes (the actual response body)
        res = @out.read(bytes.to_i)

        if header[:method] == "highlight"
          # Make sure we have a result back; else consider this an error.
          if res.nil?
            @log.warn "No highlight result back from mentos."
            stop "No highlight result back from mentos."
            raise MentosError, "No highlight result back from mentos."
          end

          # Remove the newline from Python
          res = res[0..-2]
          @log.info "Highlight in process."

          # Get the id's
          start_id = res[0..7]
          end_id = res[-8..-1]

          # Sanity check.
          if not (start_id == id and end_id == id)
            @log.error "ID's did not match. Aborting."
            stop "ID's did not match. Aborting."
            raise MentosError, "ID's did not match. Aborting."
          else
            # We're good. Remove the padding
            res = res[10..-11]
            @log.info "Highlighting complete."
            res
          end
        end
        res
      else
        @log.error "No header data back."
        stop "No header data back."
        raise MentosError, "No header received back."
      end
    end

    # With the code, prepend the id (with two spaces to avoid escaping weirdness if
    # the following text starts with a slash (like terminal code), and append the
    # id, with two padding also. This means we are sending over the 8 characters +
    # code + 8 characters.
    def add_ids(code, id)
      code.freeze
      code = id + "  #{code}  #{id}"
      code
    end

    # Write data to mentos, the Python process.
    #
    # Returns nothing.
    def write_data(out_header, code=nil)
      @in.write(out_header)
      @log.info "Out header: #{out_header}"
      @in.write(code) if code
    end

    # Sanity check for size (32-arity of 0's and 1's)
    def size_check(size)
      size_regex = /[0-1]{32}/
      if size_regex.match(size)
        true
      else
        false
      end
    end

    # Read the header via the pipe.
    #
    # Returns a header.
    def get_header
      begin
        size = @out.read(33)
        size = size[0..-2]

        # Sanity check the size
        if not size_check(size)
          @log.error "Size returned from mentos.py invalid."
          stop "Size returned from mentos.py invalid."
          raise MentosError, "Size returned from mentos.py invalid."
        end

        # Read the amount of bytes we should be expecting. We first
        # convert the string of bits into an integer.
        header_bytes = size.to_s.to_i(2) + 1
        @log.info "Size in: #{size.to_s} (#{header_bytes.to_s})"
        @out.read(header_bytes)
      rescue
        @log.error "Failed to get header."
        stop "Failed to get header."
        raise MentosError, "Failed to get header."
      end
    end

    # Return the final result for the API. Return Ruby objects for the methods that
    # want them, text otherwise.
    def return_result(res, method)
      unless method == :lexer_name_for || method == :highlight || method == :css
        res = MultiJson.load(res, :symbolize_keys => true)
      end
      res = res.rstrip if res.class == String
      res
    end

    # Convert a text header into JSON for easy access.
    def header_to_json(header)
      @log.info "[In header: #{header} "
      header = MultiJson.load(header, :symbolize_keys => true)

      if header[:error]
        # Raise this as a Ruby exception of the MentosError class.
        # Stop so we don't leave the pipe in an inconsistent state.
        @log.error "Failed to convert header to JSON."
        stop header[:error]
        raise MentosError, header[:error]
      else
        header
      end
    end

    def get_fixed_bits_from_header(out_header)
      size = out_header.bytesize

      # Fixed 32 bits to represent the int. We return a string
      # representation: e.g, "00000000000000000000000000011110"
      Array.new(32) { |i| size[i] }.reverse!.join
    end
  end
end

