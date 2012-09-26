require File.expand_path('../lib/pygments/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'pygments.rb'
  s.version = Pygments::VERSION

  s.summary = 'pygments wrapper for ruby'
  s.description = 'pygments.rb exposes the pygments syntax highlighter to Ruby'

  s.homepage = 'http://github.com/tmm1/pygments.rb'
  s.has_rdoc = false

  s.authors = ['Aman Gupta', 'Ted Nyman']
  s.email = ['aman@tmm1.net']

  s.add_dependency 'yajl-ruby',   '~> 1.1.0'
  s.add_dependency 'posix-spawn', '~> 0.3.6'
  s.add_development_dependency 'rake-compiler', '~> 0.7.6'

  # s.extensions = ['ext/extconf.rb']
  s.require_paths = ['lib']

  s.files = `git ls-files`.split("\n")
end
