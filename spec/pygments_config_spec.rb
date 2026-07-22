# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pygments do
  describe '.styles' do
    it 'includes colorful' do
      expect(described_class.styles).to include('colorful')
    end
  end

  describe '.filters' do
    it 'includes codetagify' do
      expect(described_class.filters).to include('codetagify')
    end
  end

  describe '.lexers' do
    it 'includes Ruby' do
      list = described_class.lexers

      expect(list.key?('Ruby')).to be true
      expect(list['Ruby'][:aliases]).to include('duby')
    end
  end

  describe '.formatters' do
    it 'includes Html' do
      list = described_class.formatters

      expect(list.key?('Html')).to be true
      expect(list['Html'][:aliases]).to include('html')
    end
  end
end
