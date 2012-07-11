require 'mongo'
# @author Joshua P. Mervine <joshua@mervine.net>
class Mongocached 
  # version for gem
  VERSION = '1.0.0'

  @cleanup_last = nil

  # initialize object
  def initialize options={}
    @options = defaults.merge! options

    unless @options[:lifetime].nil?
      @cleanup_last = Time.now
      @options[:cleanup_auto] = false
      @options[:cleanup_life] = ( @options[:lifetime] < 1800 ? @options[:lifetime] : 1800 )
    end

    @last = nil

    flush_expired # run cleanup 
  end

  def defaults
    {
      cache_id_prefix:              nil,
      lifetime:                     3600,
      automatic_serialization:      true,
      host:                         'localhost',
      port:                         '27017',
      dbname:                       'mongocached',
      collection:                   'cache',
      cleanup_auto:                 true,
      cleanup_life:                 1800,
      config:                       {}
    }
  end

  # return true if cache is expired
  def expired? id
    return false if @options[:lifetime].nil?
    @last = read_cache(key)
    if @last['expires'] && @last['expires'] < Time.now
      delete(id)
      true
    else
      false
    end
  end

  # returns true if cache exists
  def exists? id
    return !last_or_get(id).nil?
  end

  # expire cache
  def delete id
    @last = nil
    collection.remove(_id: id)
  end
  alias :remove :delete

  # delete all caches
  def flush
    @store.drop
  end
  alias :clean :flush

  # flush expired caches if cleanup hasn't been run recently
  def flush_expired 
    if @cleanup_last && @options[:cleanup_life] && (@cleanup_last+@options[:cleanup_life]) < Time.now
      flush_expired!
    end
  end

  # flush expired caches, ingoring when garbage collection was last run
  # TODO: does this need to be forked?
  def flush_expired!
    gcpid = Process.fork do
      collection.remove(expires: {'$lt' => Time.now})
    end
    Process.detach(gcpid)
  end
  alias :clean_expired :flush_expired!

  # create or read cache
  # - creates cache if it doesn't exist
  # - reads cache if it exists
  def save key, tags = [], ttl = @options[:lifetime]
    begin
      if expired?(key)
        data = Proc.new { yield }.call
        set( key, data, tags, ttl )
      end
      data ||= get( key )
      return data
    rescue LocalJumpError
      # when nothing is passed to yield and it's called
      return nil
    end
  end
  alias :cache :save 

  # set cache with 'key'
  # - creates cache if it doesn't exist
  # - updates cache if it does exist
  def set id, data, tags = [], ttl = @options[:lifetime]
    @last = {
      _id:      id,
      data:     data,
      tags:     tags,
      expires:  calc_expires(ttl)
    }
    collection.save( @last )
    flush_expired if gc_auto
    true
  end
  alias :add :set        # for memcached compatability
  alias :replace :set    # for memcached compatability

  # get cache with 'key'
  # - reads cache if it exists and isn't expired or raises Diskcache::NotFound
  # - if 'key' is an Array returns only keys which exist and aren't expired, it raises Diskcache::NotFound if none are available
  def get id
    if id.is_a? Array
      # TODO: more mongo'y wat to do this, perhaps a map/reduce?
      hash = {}
      id.each do |i|
        hash[i] = last_or_get(id)['data'] unless expired?(id)
      end
      raise Mongocached::NotFound if hash.nil?
      hash
    else
      @last = last_or_get(id)
      raise Mongocached::NotFound if @last.nil? || expired?(id)
      @last['data']
    end
  end
  alias :load :get

  private
  def calc_expires ttl = @options[:lifetime]
    return nil if ttl.nil?
    Time.now+ttl
  end

  def last_or_get id
    unless (@last && @last.has_key?('_id') && @last['_id'] == id)
      @last = read_cache(id)
    end
    @last
  end

  def read_cache id
    collection.find_one('_id' => id) rescue nil
  end

  def collection
    @collection ||= db[@options[:collection]]
  end

  def db
    @db ||= connection[@options[:dbname]]
  end

  def connection
    @connection ||= connect
  end

  def connect
    ::Mongo::Connection.new(@options[:host], @options[:port], @options[:config])
  end

  class NotFound < Exception
  end

end
