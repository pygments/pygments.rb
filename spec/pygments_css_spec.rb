# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pygments, '.css' do
  it 'returns css' do
    expect(described_class.css).to match(/^\.err \{/)
  end

  it 'accepts prefix' do
    expect(described_class.css('.highlight')).to match(/^\.highlight \.err \{/)
  end

  it 'accepts options' do
    expect(described_class.css(classprefix: 'code')).to match(/^\.codeerr \{/)
  end

  it 'accepts prefix and options' do
    expect(described_class.css('.mycode', classprefix: 'code')).to match(/^\.mycode \.codeerr \{/)
  end
end
