require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc 'run the generator'
task :run do
  sh "bundle exec bin/usda"
  sh "open out/index.html"
end

task :default => [:spec, :run]
