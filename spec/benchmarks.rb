#!/usr/bin/env ruby
require 'benchmark'
require 'memcached'
require File.join(File.dirname(__FILE__), '..', 'lib', 'mongocached')

# benchmarks helpers

def large_hash
  hash = {}
  (1..100).each do |i|
    hash["key#{i}"] = "foo"*100
  end
  return hash
end
# Set up data sets #
LARGE_HASH = large_hash
SMALL_STR  = "foo"
TIMES      = 100000

# print ruby version as header
puts "### Ruby #{`ruby -v | awk '{print $2}'`.chomp}"
puts " "
puts " mo = mongocached / me = memcached"

  mongocache  = Mongocached.new({ cleanup_auto: false })
  memcache = Memcached.new('localhost:11211')
  mongocache.flush
  memcache.flush

  puts " "
  puts "#### small string * #{TIMES}"
  puts "<pre>"
  dataset = SMALL_STR

  Benchmark.bm do |b|
    b.report('mo set') do
      (1..TIMES).each do
        mongocache.set("small", dataset)
      end
    end
    b.report('me set') do
      (1..TIMES).each do
        memcache.set("small", dataset)
      end
    end
    b.report('mo get') do
      (1..TIMES).each do
        mongocache.get("small") 
      end
    end
    b.report('me get') do
      (1..TIMES).each do
        memcache.get("small")
      end
    end
  end

  mongocache.flush
  memcache.flush

  puts "</pre>"
  puts " "
  puts " "
  puts "#### large hash * #{TIMES}"
  puts "<pre>"
  dataset = LARGE_HASH

  Benchmark.bm do |b|
    b.report('mo set') do
      (1..TIMES).each do
        mongocache.set("large", dataset)
      end
    end
    b.report('me set') do
      (1..TIMES).each do
        memcache.set("large", dataset)
      end
    end
    b.report('mo get') do
      (1..TIMES).each do
        x = mongocache.get("large") 
      end
    end
    b.report('me get') do
      (1..TIMES).each do
        memcache.get("large")
      end
    end
  end
  puts "</pre>"

