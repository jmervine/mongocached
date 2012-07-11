require 'simplecov'
SimpleCov.start do
    add_filter "/vendor/"
end
require 'rspec'
require 'fileutils'
require 'pp'
require './lib/mongocached'

HOST = 'localhost'
PORT = 27017
DATABASE = 'rspec'
COLLECTION = 'rspec_cache' 

STORE = Mongo::Connection.new(HOST, PORT, :pool_size => 5).db(DATABASE).collection(COLLECTION)

# create things to cache and test
class TestObject
  @value = nil
  def array
    %w{ foo bar bah }
  end
  def string
    "foo bar bah"
  end
  def num
    3
  end
  def hash
    { :foo => "foo",
      :bar => "bar",
      :bah => "bah"
    }
  end
  def obj
    TestSubObject.new 
  end
end
class TestSubObject
  attr_accessor :sub_foo, :sub_bar
  def initialize
    @sub_foo = "foo"
    @sub_bar = nil
  end
end

# delete old rspec test directories
STORE.drop
