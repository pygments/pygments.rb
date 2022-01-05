# frozen_string_literal: true

require_relative 'lib/pygments/version'

Gem::Specification.new do |s|
  s.name = 'pygments.rb'
  s.version = Pygments::VERSION

  s.summary = 'pygments wrapper for ruby'
  s.description = 'pygments.rb is a Ruby wrapper for Pygments syntax highlighter'
  s.license = 'MIT'
  s.homepage = 'https://github.com/pygments/pygments.rb'

  s.authors = ['Aman Gupta', 'Ted Nyman', 'Marat Radchenko']
  s.email = ['marat@slonopotamus.org']

  s.metadata = {
    'homepage_uri' => s.homepage,
    'bug_tracker_uri' => "#{s.homepage}/issues",
    'changelog_uri' => "#{s.homepage}/blob/master/CHANGELOG.adoc",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}",
    'source_code_uri' => s.homepage
  }

  s.required_ruby_version = '>= 2.3.0'

  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'rubocop', '~> 0.81.0'
  s.add_development_dependency 'test-unit', '~> 3.5.0'

  s.files = `git ls-files -z`.split("\0").reject { |f| File.symlink?(f) }
end
