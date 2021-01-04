require File.expand_path('../lib/pygments/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'pygments.rb'
  s.version = Pygments::VERSION

  s.summary = 'pygments wrapper for ruby'
  s.description = 'pygments.rb exposes the pygments syntax highlighter to Ruby'

  s.homepage = 'https://github.com/tmm1/pygments.rb'

  s.authors = ['Aman Gupta', 'Ted Nyman']
  s.email = ['aman@tmm1.net']
  s.license = 'MIT'

  s.add_dependency 'multi_json', '>= 1.0.0'
  s.add_development_dependency 'rake-compiler', '~> 1.1.0'
  s.add_development_dependency 'test-unit', '~> 3.3.0'

  # s.extensions = ['ext/extconf.rb']
  s.require_paths = ['lib']

  s.files = `git ls-files`.split("\n").select { |f| !File.symlink?(f) } + ['lexers']
end
