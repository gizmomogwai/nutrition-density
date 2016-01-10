#require "bundler/gem_tasks"
#require "rspec/core/rake_task"
#
#RSpec::Core::RakeTask.new(:spec)
#
#directory 'out'
#
#desc 'run the generator'
#task :run => ['out']do
#  sh "bundle exec bin/usda"
#  sh "open out/index.html"
#end
#
#task :default => [:spec, :run]

directory 'out'

file 'out/rotate-headers.css' => ['views/rotate-headers.css', 'out'] do |t|
  sh "cp #{t.prerequisites.first} #{t.name}"
end

desc 'run the d program'
task :run => ['out', 'out/rotate-headers.css'] do
  sh 'dub run'
end
task :default => [:run]
