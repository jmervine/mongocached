# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'mongocached'
 
Gem::Specification.new do |s|
  s.name        = "mongocached"
  s.version     = Mongocached::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Joshua Mervine"]
  s.email       = ["joshua@mervine.net"]
  s.homepage    = "http://mongocached.rubyops.net/"
  s.summary     = "Simple disk cache"
  s.description = "Simple mongodb based cache for things like Sinatra and Rails which is implemented much like Memcached in hopes that in some cases they're interchangeable. It's based off 'diskcached'"
 
  s.required_rubygems_version = ">= 1.3.6"
  #s.rubyforge_project         = ""
 
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rdoc"
 
  s.files        = Dir.glob("lib/**/*") + %w(README.md HISTORY.md Benchmark.md Gemfile Rakefile)
  s.require_path = 'lib'
end

