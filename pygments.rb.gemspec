# frozen_string_literal: true

require File.expand_path('lib/pygments/version', __dir__)

Gem::Specification.new do |s|
  s.name = 'pygments.rb'
  s.version = Pygments::VERSION

  s.summary = 'pygments wrapper for ruby'
  s.description = 'pygments.rb is a Ruby wrapper for Pygments syntax highlighter'

  s.homepage = 'https://github.com/pygments/pygments.rb'
  s.required_ruby_version = '>= 2.3.0'

  s.authors = ['Aman Gupta', 'Ted Nyman', 'Marat Radchenko']
  s.email = ['marat@slonopotamus.org']
  s.license = 'MIT'

  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'rubocop', '~> 0.81.0'
  s.add_development_dependency 'test-unit', '~> 3.4.0'

  # s.extensions = ['ext/extconf.rb']
  s.require_paths = ['lib']

  s.files = `git ls-files`.split("\n").reject { |f| File.symlink?(f) } + ['lexers']
end
