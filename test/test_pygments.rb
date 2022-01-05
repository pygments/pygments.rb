# frozen_string_literal: true

require 'test/unit'
require File.join(File.dirname(__FILE__), '..', '/lib/pygments.rb')
ENV['mentos-test'] = 'yes'

P = Pygments
PE = Pygments.engine

class PygmentsHighlightTest < Test::Unit::TestCase
  RUBY_CODE = "#!/usr/bin/ruby\nputs 'foo'"
  RUBY_CODE_TRAILING_NEWLINE = "#!/usr/bin/ruby\nputs 'foo'\n"
  TEST_CODE = File.read(
    File.join(__dir__, '..', 'lib', 'pygments', 'mentos.py')
  )

  def test_highlight_defaults_to_html
    code = P.highlight(RUBY_CODE)
    assert_match '<span class="ch">#!/usr/bin/ruby</span>', code
    assert_equal '<div class', code[0..9]
  end

  def test_full_html_highlight
    code = P.highlight(RUBY_CODE)
    assert_match '<span class="ch">#!/usr/bin/ruby</span>', code
    assert_equal %(<div class="highlight"><pre><span></span><span class="ch">#!/usr/bin/ruby</span>
<span class="nb">puts</span> <span class="s1">&#39;foo&#39;</span>
</pre></div>), code
  end

  def test_highlight_works_with_larger_files
    code = P.highlight(TEST_CODE)
    assert_match 'Main loop, waiting for inputs on stdin', code
  end

  def test_raises_exception_on_timeout
    assert_raise MentosError.new('Timeout on a mentos highlight call') do
      # Assume highlighting a large file will take more than 1 millisecond
      P.highlight(TEST_CODE * 10, timeout: 0.001)
    end
  end

  def test_highlight_works_with_null_bytes
    code = P.highlight("\0hello", lexer: 'rb')
    assert_match 'hello', code
  end

  def test_highlight_works_on_utf8
    code = P.highlight('# ø', lexer: 'rb', options: { encoding: 'utf-8' })
    assert_match '# ø', code
  end

  def test_highlight_works_on_utf8_automatically
    code = P.highlight('# ø', lexer: 'rb')
    assert_match '# ø', code
  end

  def test_highlight_works_on_utf8_all_chars_automatically
    code = P.highlight('def foo: # ø', lexer: 'py')

    assert_equal '<div class="highlight"><pre><span></sp', code[0, 38]
  end

  def test_highlight_works_with_multiple_utf8
    code = P.highlight('# ø ø ø', lexer: 'rb', options: { encoding: 'utf-8' })
    assert_match '# ø ø ø', code
  end

  def test_highlight_works_with_multiple_utf8_and_trailing_newline
    code = P.highlight("#!/usr/bin/ruby\nputs 'ø..ø'\n", lexer: 'rb')
    assert_match 'ø..ø', code
  end

  def test_highlight_formatter_bbcode
    code = P.highlight(RUBY_CODE, formatter: 'bbcode')
    assert_match 'color=#408080][i]#!/usr/bin/ruby[/i]', code
  end

  def test_highlight_formatter_terminal
    code = P.highlight(RUBY_CODE, formatter: 'terminal')
    assert_match '39;49;00m', code
  end

  def test_highlight_options
    code = P.highlight(RUBY_CODE, options: { full: true, title: 'test' })
    assert_match '<title>test</title>', code
  end

  def test_highlight_works_with_trailing_newline
    code = P.highlight(RUBY_CODE_TRAILING_NEWLINE)
    assert_match '<span class="ch">#!/usr/bin/ruby</span>', code
  end

  def test_highlight_works_with_multiple_newlines
    code = P.highlight("#{RUBY_CODE_TRAILING_NEWLINE}derp\n\n")
    assert_match '<span class="ch">#!/usr/bin/ruby</span>', code
  end

  def test_highlight_works_with_trailing_cr
    code = P.highlight("#{RUBY_CODE_TRAILING_NEWLINE}\r")
    assert_match '<span class="ch">#!/usr/bin/ruby</span>', code
  end

  def test_highlight_still_works_with_invalid_code
    code = P.highlight('importr python;    wat?', lexer: 'py')
    assert_match '>importr</span>', code
  end

  def test_version
    version_str = P.pygments_version
    # This will throw "Malformed version number string" ArgumentError if version_str is not a valid version string
    Gem::Version.new(version_str)
  end

  def test_highlight_on_multi_threads
    omit 'We do not actually support multithreading'

    10.times.map do
      Thread.new do
        test_full_html_highlight
      end
    end.each(&:join)
  end
end

class PygmentsLexerTest < Test::Unit::TestCase
  RUBY_CODE = "#!/usr/bin/ruby\nputs 'foo'"

  def test_lexer_by_mimetype
    assert_includes P.lexer_names_for(mimetype: 'text/x-ruby'), 'rb'
    assert_equal 'json', P.lexer_name_for(mimetype: 'application/json')
  end

  def test_lexer_by_filename
    assert_includes P.lexer_names_for(filename: 'test.rb'), 'rb'
    assert_equal 'scala', P.lexer_name_for(filename: 'test.scala')
  end

  def test_lexer_by_name
    assert_includes P.lexer_names_for(lexer: 'ruby'), 'rb'
    assert_equal 'python', P.lexer_name_for(lexer: 'python')
    assert_equal 'c', P.lexer_name_for(lexer: 'c')
  end

  def test_lexer_by_filename_and_content
    assert_includes P.lexer_names_for(RUBY_CODE, filename: 'test.rb'), 'rb'
  end

  def test_lexer_by_content
    assert_includes P.lexer_names_for(RUBY_CODE), 'rb'
  end

  def test_lexer_by_nothing
    assert_raise MentosError do
      P.lexer_name_for(invalid: true)
    end
  end
end

class PygmentsLexerClassTest < Test::Unit::TestCase
  def test_find
    assert_equal 'Ruby', P::Lexer['Ruby'].name
    assert_equal 'Ruby', P::Lexer['ruby'].name
    assert_equal 'Ruby', P::Lexer['rb'].name
    assert_equal 'Ruby', P::Lexer['rake'].name
    assert_equal 'Ruby', P::Lexer['gemspec'].name
  end

  def test_find_by_name
    assert_equal P::Lexer['Ruby'], P::Lexer.find_by_name('Ruby')
    assert_equal P::Lexer['C'], P::Lexer.find_by_name('C')
  end

  def test_find_by_alias
    assert_equal P::Lexer['Ruby'], P::Lexer.find_by_alias('rb')
    assert_equal P::Lexer['Ruby'], P::Lexer.find_by_alias('ruby')
    assert_equal P::Lexer['Scala'], P::Lexer.find_by_alias('scala')
    assert_equal P::Lexer['Go'], P::Lexer.find_by_alias('go')
  end

  def test_find_lexer_by_extname
    assert_equal P::Lexer['Ruby'], P::Lexer.find_by_extname('.rb')
    assert_equal P::Lexer['PHP'], P::Lexer.find_by_extname('.php4')
    assert_equal P::Lexer['PHP'], P::Lexer.find_by_extname('.php5')
    assert_equal P::Lexer['Groff'], P::Lexer.find_by_extname('.1')
    assert_equal P::Lexer['Groff'], P::Lexer.find_by_extname('.3')
    assert_equal P::Lexer['C'], P::Lexer.find_by_extname('.c')
    assert_equal P::Lexer['Python'], P::Lexer.find_by_extname('.py')
    assert_equal P::Lexer['Java'], P::Lexer.find_by_extname('.java')
  end

  def test_find_lexer_by_mimetype
    assert_equal P::Lexer['Ruby'], P::Lexer.find_by_mimetype('text/x-ruby')
    assert_equal P::Lexer['JSON'], P::Lexer.find_by_mimetype('application/json')
    assert_equal P::Lexer['Python'], P::Lexer.find_by_mimetype('text/x-python')
  end
end

class PygmentsCssTest < Test::Unit::TestCase
  include Pygments

  def test_css
    assert_match(/^\.err \{/, P.css)
  end

  def test_css_prefix
    assert_match(/^\.highlight \.err \{/, P.css('.highlight'))
  end

  def test_css_options
    assert_match(/^\.codeerr \{/, P.css(classprefix: 'code'))
  end

  def test_css_prefix_and_options
    assert_match(/^\.mycode \.codeerr \{/, P.css('.mycode', classprefix: 'code'))
  end

  def test_css_default
    assert_match '.c { color: #408080; font-style: italic }', P.css
  end

  def test_css_colorful
    assert_match '.c { color: #888888 }', P.css(style: 'colorful')
  end
end

class PygmentsConfigTest < Test::Unit::TestCase
  def test_styles
    assert P.styles.include?('colorful')
  end

  def test_filters
    assert P.filters.include?('codetagify')
  end

  def test_lexers
    list = P.lexers
    assert list.key?('Ruby')
    assert list['Ruby'][:aliases].include?('duby')
  end

  def test_formatters
    list = P.formatters
    assert list.key?('Html')
    assert list['Html'][:aliases].include?('html')
  end
end
