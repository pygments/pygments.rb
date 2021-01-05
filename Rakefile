#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: :test

# ==========================================================
# Packaging
# ==========================================================

GEMSPEC = eval(File.read('pygments.rb.gemspec'))

require 'rubygems/package_task'

# ==========================================================
# Testing
# ==========================================================

require 'rake/testtask'
Rake::TestTask.new 'test' do |t|
  t.test_files = FileList['test/test_*.rb']
end

# ==========================================================
# Benchmarking
# ==========================================================

task :bench do
  sh 'ruby bench.rb'
end

# ==========================================================
# Cache lexers
# ==========================================================

# Write all the lexers to a file for easy lookup
task :lexers do
  sh 'ruby cache-lexers.rb'
end

task(:test).enhance([:lexers])
task(:build).enhance([:lexers])

# ==========================================================
# Vendor
# ==========================================================

namespace :vendor do
  file 'vendor/pygments-main' do |f|
    sh "pip install --target=#{f.name} pygments"
  end

  task :clobber do
    rm_rf 'vendor/pygments-main'
  end

  # Load all the custom lexers in the `vendor/custom_lexers` folder
  # and stick them in our custom Pygments vendor
  task :load_lexers do
    LEXERS_DIR = 'vendor/pygments-main/pygments/lexers'
    lexers = FileList['vendor/custom_lexers/*.py']
    lexers.each { |l| FileUtils.copy l, LEXERS_DIR }
    FileUtils.cd(LEXERS_DIR) { sh 'python _mapping.py' }
  end

  desc 'update vendor/pygments-main'
  task update: [:clobber, 'vendor/pygments-main', :load_lexers]
end
