require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => [:spec, :run]

task :run do
  sh "bundle exec bin/usda"
  sh "open out.html"
end
