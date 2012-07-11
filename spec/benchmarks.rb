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
puts "## Ruby #{`ruby -v | awk '{print $2}'`.chomp}"

  mongocache  = Mongocached.new
  memcache = Memcached.new('localhost:11211')

  puts " "
  puts "#### small string * #{TIMES}"
  dataset = SMALL_STR

  mongocache.set('read', dataset)
  memcache.set 'read', dataset

  Benchmark.bm do |b|
    b.report('mongocached set') do
      (1..TIMES).each do
        mongocache.set('write', dataset)
      end
    end
    b.report('memcached  set') do
      (1..TIMES).each do
        memcache.set 'write', dataset
      end
    end
    b.report('mongocached get') do
      (1..TIMES).each do
        x = mongocache.get('read') 
      end
    end
    b.report('memcached  get') do
      (1..TIMES).each do
        memcache.get 'read'
      end
    end
  end

  mongocache.flush

  puts " "
  puts " "
  puts "#### large hash * #{TIMES}"
  dataset = LARGE_HASH

  mongocache.cache('read') { dataset }
  memcache.set 'read', dataset
  Benchmark.bm do |b|
    b.report('mongocached set') do
      (1..TIMES).each do
        mongocache.set('write', dataset)
      end
    end
    b.report('memcached  set') do
      (1..TIMES).each do
        memcache.set 'write', dataset
      end
    end
    b.report('mongocached get') do
      (1..TIMES).each do
        x = mongocache.get('read') 
      end
    end
    b.report('memcached  get') do
      (1..TIMES).each do
        memcache.get 'read'
      end
    end
  end

