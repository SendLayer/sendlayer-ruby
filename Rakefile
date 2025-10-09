require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new

task default: [:spec, :rubocop]

desc 'Run all tests and code quality checks'
task ci: [:spec, :rubocop]

desc 'Build the gem'
task :build do
  sh 'gem build sendlayer.gemspec'
end

desc 'Install the gem locally'
task install: :build do
  sh 'gem install sendlayer-*.gem'
end

desc 'Clean up generated files'
task :clean do
  sh 'rm -f sendlayer-*.gem'
  sh 'rm -rf coverage/'
  sh 'rm -rf .rspec_status'
end
