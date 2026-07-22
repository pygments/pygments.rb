# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pygments::Lexer do
  describe '.find' do
    it 'finds by name' do
      expect(described_class['Ruby'].name).to eq('Ruby')
    end

    it 'finds by lowercase name' do
      expect(described_class['ruby'].name).to eq('Ruby')
    end

    it 'finds by alias' do
      expect(described_class['rb'].name).to eq('Ruby')
    end

    it 'finds by filename' do
      expect(described_class['rake'].name).to eq('Ruby')
    end

    it 'finds by extension' do
      expect(described_class['gemspec'].name).to eq('Ruby')
    end
  end

  describe '.find_by_name' do
    it 'finds Ruby' do
      expect(described_class.find_by_name('Ruby')).to eq(described_class['Ruby'])
    end

    it 'finds C' do
      expect(described_class.find_by_name('C')).to eq(described_class['C'])
    end
  end

  describe '.find_by_alias' do
    it 'finds Ruby by rb' do
      expect(described_class.find_by_alias('rb')).to eq(described_class['Ruby'])
    end

    it 'finds Ruby by ruby' do
      expect(described_class.find_by_alias('ruby')).to eq(described_class['Ruby'])
    end

    it 'finds Scala' do
      expect(described_class.find_by_alias('scala')).to eq(described_class['Scala'])
    end

    it 'finds Go' do
      expect(described_class.find_by_alias('go')).to eq(described_class['Go'])
    end
  end

  describe '.find_by_extname' do
    it 'finds Ruby by .rb' do
      expect(described_class.find_by_extname('.rb')).to eq(described_class['Ruby'])
    end

    it 'finds PHP by .php4' do
      expect(described_class.find_by_extname('.php4')).to eq(described_class['PHP'])
    end

    it 'finds PHP by .php5' do
      expect(described_class.find_by_extname('.php5')).to eq(described_class['PHP'])
    end

    it 'finds C by .c' do
      expect(described_class.find_by_extname('.c')).to eq(described_class['C'])
    end

    it 'finds Python by .py' do
      expect(described_class.find_by_extname('.py')).to eq(described_class['Python'])
    end

    it 'finds Java by .java' do
      expect(described_class.find_by_extname('.java')).to eq(described_class['Java'])
    end
  end

  describe '.find_by_mimetype' do
    it 'finds Ruby by text/x-ruby' do
      expect(described_class.find_by_mimetype('text/x-ruby')).to eq(described_class['Ruby'])
    end

    it 'finds JSON by application/json' do
      expect(described_class.find_by_mimetype('application/json')).to eq(described_class['JSON'])
    end

    it 'finds Python by text/x-python' do
      expect(described_class.find_by_mimetype('text/x-python')).to eq(described_class['Python'])
    end
  end
end
