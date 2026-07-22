#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: :spec

require 'rubygems/package_task'

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# ==========================================================
# Benchmarking
# ==========================================================

desc 'run benchmarks'
task :bench do
  sh 'ruby bench.rb'
end

# ==========================================================
# Vendor
# ==========================================================

namespace :vendor do
  file 'vendor/pygments-main' do |f|
    sh "pip install --target=#{f.name} pygments"
    sh "git add -f -- #{f.name}"
  end

  desc 'remove vendor/pygments-main'
  task :clobber do
    rm_rf 'vendor/pygments-main'
  end

  desc 'update vendor/pygments-main'
  task update: [:clobber, 'vendor/pygments-main']
end
