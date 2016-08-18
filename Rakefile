require 'rake/testtask'

task :console do
  require 'pry'
  require './lib/fb_client'
  
  binding.pry
end


Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test