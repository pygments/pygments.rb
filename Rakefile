task :default => :test

# ==========================================================
# Packaging
# ==========================================================

GEMSPEC = eval(File.read('pygments.rb.gemspec'))

require 'rake/gempackagetask'
Rake::GemPackageTask.new(GEMSPEC) do |pkg|
end

# ==========================================================
# Ruby Extension
# ==========================================================

require 'rake/extensiontask'
Rake::ExtensionTask.new('pygments_ext', GEMSPEC) do |ext|
  ext.ext_dir = 'ext'
end
task :build => :compile

# ==========================================================
# Testing
# ==========================================================

require 'rake/testtask'
Rake::TestTask.new 'test' do |t|
  t.test_files = FileList['test/test_*.rb']
  t.ruby_opts = ['-rubygems']
end
task :test => :build

# ==========================================================
# Vendor
# ==========================================================

namespace :vendor do
  file 'vendor/pygments-main' do |f|
    sh "hg clone https://bitbucket.org/birkenfeld/pygments-main #{f.name}"
    sh "hg --repository #{f.name} identify --id > #{f.name}/REVISION"
    rm_rf Dir["#{f.name}/.hg*"]
  end

  task :clobber do
    rm_rf 'vendor/pygments-main'
  end

  task :update => [:clobber, 'vendor/pygments-main']
end
