require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'

spec_data = File.open('monkey_wrench.gemspec').read
spec = nil
Thread.new do
  spec = eval("#{spec_data}")
end.join

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end