# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pygments do
  let(:ruby_code) { "#!/usr/bin/ruby\nputs 'foo'" }

  describe '.lexer_names_for' do
    it 'looks up lexer by mimetype' do
      expect(described_class.lexer_names_for(mimetype: 'text/x-ruby')).to include('rb')
    end

    it 'looks up lexer by filename' do
      expect(described_class.lexer_names_for(filename: 'test.rb')).to include('rb')
    end

    it 'looks up lexer by name' do
      expect(described_class.lexer_names_for(lexer: 'ruby')).to include('rb')
    end

    it 'looks up lexer by filename and content' do
      expect(described_class.lexer_names_for(ruby_code, filename: 'test.rb')).to include('rb')
    end

    it 'looks up lexer by content' do
      expect(described_class.lexer_names_for(ruby_code)).to include('rb')
    end
  end

  describe '.lexer_name_for' do
    it 'returns single lexer by mimetype' do
      expect(described_class.lexer_name_for(mimetype: 'application/json')).to eq('json')
    end

    it 'returns single lexer by filename' do
      expect(described_class.lexer_name_for(filename: 'test.scala')).to eq('scala')
    end

    it 'returns single lexer by name' do
      expect(described_class.lexer_name_for(lexer: 'python')).to eq('python')
      expect(described_class.lexer_name_for(lexer: 'c')).to eq('c')
    end

    it 'raises on invalid input' do
      expect { described_class.lexer_name_for(invalid: true) }
        .to raise_error(MentosError)
    end
  end
end
