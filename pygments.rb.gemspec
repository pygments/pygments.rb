require File.expand_path('../lib/pygments/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'pygments.rb'
  s.version = Pygments::VERSION

  s.summary = 'pygments wrapper for ruby'
  s.description = 'pygments.rb exposes the pygments syntax highlighter via embedded python'

  s.homepage = 'http://github.com/tmm1/pygments.rb'
  s.has_rdoc = false

  s.authors = ['Aman Gupta']
  s.email = ['aman@tmm1.net']

  s.add_dependency 'rubypython', '>= 0.5.1'
  s.add_development_dependency 'rake-compiler', '0.7.6'

  # s.extensions = ['ext/extconf.rb']
  s.require_paths = ['lib']

  s.files = `git ls-files`.split("\n")
end
