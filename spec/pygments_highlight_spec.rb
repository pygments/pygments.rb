# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pygments, '.highlight' do
  let(:ruby_code) { "#!/usr/bin/ruby\nputs 'foo'" }
  let(:ruby_code_trailing_newline) { "#!/usr/bin/ruby\nputs 'foo'\n" }
  let(:test_code) { File.read(File.join(__dir__, '..', 'lib', 'pygments', 'mentos.py')) }

  it 'defaults to html' do
    code = described_class.highlight(ruby_code)

    expect(code).to include('<span class="ch">#!/usr/bin/ruby</span>')
    expect(code[0..9]).to eq('<div class')
  end

  it 'works with larger files' do
    code = described_class.highlight(test_code)

    expect(code).to include('Main loop, waiting for inputs on stdin')
  end

  it 'raises exception on timeout' do
    # Assume highlighting a large file will take more than 1 millisecond
    expect { described_class.highlight(test_code * 10, timeout: 0.001) }
      .to raise_error(MentosError, 'Timeout on a mentos highlight call')
  end

  it 'works with null bytes' do
    code = described_class.highlight("\0hello", lexer: 'rb')

    expect(code).to include('hello')
  end

  it 'works on utf8' do
    code = described_class.highlight('# ø', lexer: 'rb', options: { encoding: 'utf-8' })

    expect(code).to include('# ø')
  end

  it 'works on utf8 automatically' do
    code = described_class.highlight('# ø', lexer: 'rb')

    expect(code).to include('# ø')
  end

  it 'works on utf8 all chars automatically' do
    code = described_class.highlight('def foo: # ø', lexer: 'py')

    expect(code[0, 38]).to eq('<div class="highlight"><pre><span></sp')
  end

  it 'works with multiple utf8' do
    code = described_class.highlight('# ø ø ø', lexer: 'rb', options: { encoding: 'utf-8' })

    expect(code).to include('# ø ø ø')
  end

  it 'works with multiple utf8 and trailing newline' do
    code = described_class.highlight("#!/usr/bin/ruby\nputs 'ø..ø'\n", lexer: 'rb')

    expect(code).to include('ø..ø')
  end

  it 'supports terminal formatter' do
    code = described_class.highlight(ruby_code, formatter: 'terminal')

    expect(code).to include('39;49;00m')
  end

  it 'accepts options' do
    code = described_class.highlight(ruby_code, options: { full: true, title: 'test' })

    expect(code).to include('<title>test</title>')
  end

  it 'works with trailing newline' do
    code = described_class.highlight(ruby_code_trailing_newline)

    expect(code).to include('<span class="ch">#!/usr/bin/ruby</span>')
  end

  it 'works with multiple newlines' do
    code = described_class.highlight("#{ruby_code_trailing_newline}derp\n\n")

    expect(code).to include('<span class="ch">#!/usr/bin/ruby</span>')
  end

  it 'works with trailing cr' do
    code = described_class.highlight("#{ruby_code_trailing_newline}\r")

    expect(code).to include('<span class="ch">#!/usr/bin/ruby</span>')
  end

  it 'still works with invalid code' do
    code = described_class.highlight('importr python;    wat?', lexer: 'py')

    expect(code).to include('>importr</span>')
  end

  describe '.pygments_version' do
    it 'returns a valid version string' do
      version_str = described_class.pygments_version

      # This will throw "Malformed version number string" ArgumentError if version_str is not a valid version string
      expect { Gem::Version.new(version_str) }.not_to raise_error
    end
  end

  describe 'multi-threaded highlighting' do
    it 'works on multiple threads', skip: 'multithreading is not supported' do
      10.times.map do
        Thread.new do
          described_class.highlight(ruby_code)
        end
      end.each(&:join)
    end
  end
end
