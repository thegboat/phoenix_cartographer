#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

# If you want to make this the default task
task :default => :spec

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r phoenix_cartographer.rb"
end

task :test_console do
  sh "irb -rubygems -I lib -r phoenix_cartographer.rb -I spec -r spec_helper.rb "
end