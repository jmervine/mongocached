require 'spec_helper.rb'

describe Mongocached do
  describe '#new' do
    it "should init" do
      expect { @cache = Mongocached.new() }.to_not raise_error
    end
    it "should init with options" do
      pending
    end
  end

  describe "#set", "(alias #add, #replace)" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
    end
    it "should create a new cache" do
      @cache.set('test1', "test string").should be_true
    end
    it "should create a cache in mongo" do
      STORE.find_one(_id: 'test1').should be
    end
  end

  describe "#get", "single" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
    end
    it "should read cache before expiration" do
      @cache.get('test1').should eq "test string"
      @cache.get('test1').should be_a_kind_of String
    end
    it "should expire correctly" do
      sleep 0.5
      expect { @cache.get('test1') }.to raise_error /NotFound/
    end
  end

  describe "#get", "multiple" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
      @cache.set('test1', "test string")
      @cache.set('test2', "test string")
    end
    it "should read multiple caches into a Hash" do
      @cache.get(['test1', 'test2']).should be_a_kind_of Hash
      @cache.get(['test1', 'test2']).keys.count.should eq 2
      @cache.get(['test1', 'test2'])['test1'].should eq "test string"
    end
    it "should expire correctly" do
      sleep 0.51
      expect { @cache.get(['test1', 'test2']) }.to raise_error /NotFound/
    end
  end

  describe "#cache" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
    end
    it "should create a new cache" do
      @cache.cache('test1') { "test string" }.should eq "test string"
      @cache.get('test1').should eq "test string"
    end
    it "should create a cache in mongo" do
      STORE.find_one(_id: 'test1').should be
    end
    it "should read cache before expiration" do
      @cache.cache('test1') { "test string" }.should eq "test string"
      @cache.cache('test1') { "test string" }.should be_a_kind_of String
    end
    it "should expire correctly" do
      sleep 0.51
      @cache.cache('test1') do
        "new test string"
      end.should eq "new test string"
    end
    it "should return nil if no block is passed and cache is expired" do
      sleep 0.51 
      @cache.cache('test1').should be_nil
    end
  end

  describe "#delete" do
    before(:all) do
      @cache = Mongocached.new()
      @cache.cache('test3') { "cache test3" }
    end
    it "should expire cache" do
      expect { @cache.get('test3') }.to_not raise_error
      expect { @cache.delete('test3') }.to_not raise_error
      expect { @cache.get('test3') }.to raise_error
    end
    it "should remove cache entry" do
      STORE.find_one(_id: 'test3' ).should_not be
    end
  end

  describe "#flush" do
    before(:all) do
      @cache = Mongocached.new()
      @cache.cache('test4') { "cache test4" }
      @cache.cache('test5') { "cache test5" }
      @cache.cache('test6') { "cache test6" }
    end
    it "should flush all caches" do
      expect { @cache.flush }.to_not raise_error
      STORE.find.count.should eq 0
    end
  end

  describe "#flush_expired" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
      @cache.cache('flush1') { "cache flush" }
    end
    it "should not flush caches that aren't expired" do
      expect { @cache.flush_expired }.to_not raise_error
      @cache.get('flush1').should eq 'cache flush'
    end
    it "should not flush caches if caches recently flushed" do
      sleep 0.5
      @cache.instance_variable_set(:@cleanup_last, Time.now)
      expect { @cache.flush_expired }.to_not raise_error
      STORE.find_one(_id: 'flush1').should_not be_nil
    end
    it "should flush caches are are expired" do
      sleep 0.5
      expect { @cache.flush_expired }.to_not raise_error
      expect { @cache.get('flush1') }.to raise_error /NotFound/
      STORE.find_one(_id: 'flush1').should be_nil
    end
  end

  describe "#flush_expired!" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
      @cache.cache('flush1') { "cache flush" }
    end
    it "should not flush caches that aren't expired" do
      expect { @cache.flush_expired! }.to_not raise_error
      expect { @cache.get('flush1') }.to_not raise_error /NotFound/
    end
    it "should flush caches even when recently flushed" do
      sleep 0.5
      @cache.instance_variable_set(:@cleanup_last, Time.now)
      expect { @cache.flush_expired! }.to_not raise_error
      expect { @cache.get('flush1') }.to raise_error /NotFound/
      STORE.find_one(_id: 'flush1').should be_nil
    end
  end

  describe "automatic garbage collection ON" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5 })
      @cache.flush
      @cache.set('test8', "cache test8")
      @cache.set('test9', "cache test9")
      @cache.set('test10', "cache test10")
    end
    it "should clean up expired caches" do
      sleep 0.51 
      @cache.instance_variable_set(:@cleanup_last, Time.now-1)
      expect { @cache.set('test10', "cache test10") }.to_not raise_error
      sleep 0.5
      STORE.find_one(_id: 'test8').should be_nil
      STORE.find_one(_id: 'test9').should be_nil
      STORE.find_one(_id: 'test10').should_not be_nil
    end
  end

  describe "automatic garbage collection OFF" do
    before(:all) do
      @cache = Mongocached.new({ lifetime: 0.5, cleanup_auto: false  })
      @cache.cache('test8') { "cache test8" }
      @cache.cache('test9') { "cache test9" }
      @cache.cache('test10') { "cache test10" }
    end
    it "should not clean up expired caches" do
      sleep 0.51
      expect { @cache.cache('test10') { "cache test10" } }.to_not raise_error
      sleep 0.1
      STORE.find_one(_id: 'test8')["data"].should be
      STORE.find_one(_id: 'test9')["data"].should be
      STORE.find_one(_id: 'test10')["data"].should be
    end
  end

end

describe Mongocached, "advanced test cases" do
  before(:all) do
    @cache = Mongocached.new()
    @testo = TestObject.new
  end

  it "should cache array" do
    @cache.cache('array') { @testo.array }
    @cache.cache('array').should be_a_kind_of Array
    @cache.cache('array').count.should eq 3

    @cache.set('array1', @testo.array)
    @cache.get('array1').should be_a_kind_of Array
    @cache.get('array1').count.should eq 3
  end

  it "should cache string" do
    @cache.cache('string') { @testo.string }
    @cache.cache('string').should be_a_kind_of String
    @cache.cache('string').should eq "foo bar bah"

    @cache.set('string1', @testo.string)
    @cache.get('string1').should be_a_kind_of String
    @cache.get('string1').should eq "foo bar bah"
  end

  it "should cache number" do
    @cache.cache('num') { @testo.num }
    @cache.cache('num').should be_a_kind_of Integer
    @cache.cache('num').should eq 3

    @cache.set('num1', @testo.num)
    @cache.get('num1').should be_a_kind_of Integer
    @cache.get('num1').should eq 3
  end

  it "should cache hash" do
    @cache.cache('hash') { @testo.hash }
    @cache.cache('hash').should be_a_kind_of Hash
    @cache.cache('hash').should have_key :foo

    @cache.set('hash1', @testo.hash)
    @cache.get('hash1').should be_a_kind_of Hash
    @cache.get('hash1').should have_key :foo
  end

  it "should cache simple objects" do
    @cache.cache('object') { @testo.obj }
    @cache.cache('object').should be_a_kind_of TestSubObject
    @cache.cache('object').sub_foo.should eq "foo"

    @cache.set('object1', @testo.obj)
    @cache.get('object1').should be_a_kind_of TestSubObject
    @cache.get('object1').sub_foo.should eq "foo"
  end
  it "should cache modified objects" do
    @cache.delete('object')
    @cache.cache('object') do 
      o = @testo.obj
      o.sub_bar = 'bar'
      o
    end
    @cache.cache('object').should be_a_kind_of TestSubObject
    @cache.cache('object').sub_bar.should eq 'bar'
  end 
  it "should cache complex objects" do
    # might be redundant, but tests more complexity
    @cache.delete('object')
    @cache.cache('object') { TestObject.new }
    @cache.cache('object').array.should be_a_kind_of Array
    @cache.cache('object').string.should be_a_kind_of String
    @cache.cache('object').hash.should be_a_kind_of Hash
    @cache.cache('object').obj.should be_a_kind_of TestSubObject
  end

end
