#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: :test

# ==========================================================
# Packaging
# ==========================================================

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
# Vendor
# ==========================================================

namespace :vendor do
  file 'vendor/pygments-main' do |f|
    sh "pip install --target=#{f.name} pygments"
    sh "git add -- #{f.name}"
  end

  task :clobber do
    rm_rf 'vendor/pygments-main'
  end

  desc 'update vendor/pygments-main'
  task update: [:clobber, 'vendor/pygments-main']
end
