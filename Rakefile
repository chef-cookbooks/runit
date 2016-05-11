require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'
require 'foodcritic'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: [:rubocop, :foodcritic, :spec]

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = './test/unit{,/*/**}/*_spec.rb'
end

FoodCritic::Rake::LintTask.new do |t|
  t.options = { fail_tags: ['correctness'] }
end

RuboCop::RakeTask.new

begin
  require 'kitchen/rake_tasks'
  Kitchen::RakeTasks.new
rescue LoadError
  puts '>>>>> Kitchen gem not loaded, omitting tasks' unless ENV['CI']
end

begin
  require 'emeril/rake'
rescue LoadError
  puts '>>>>> Emeril gem not loaded, omitting tasks' unless ENV['CI']
end
