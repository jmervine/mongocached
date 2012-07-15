require 'mongo'
# @author Joshua P. Mervine <joshua@mervine.net>
class Mongocached 
  # version for gem
  VERSION = '1.0.2'

  @cleanup_last = nil
  @ensure_indexes = false

  # initialize object
  def initialize options={}

    @options = defaults.merge! options

    unless @options[:lifetime].nil?
      @cleanup_last = Time.now
      @options[:cleanup_life] = ( @options[:lifetime] < 1800 ? @options[:lifetime] : 1800 )
    else
      @options[:cleanup_auto] = false
    end

    @last = nil

    flush_expired!
  end

  def defaults
    {
      #cache_id_prefix:              nil,
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

  # expire cache
  def delete id
    @last = nil
    collection.remove(_id: id)
  end
  alias :remove :delete

  # delete all caches
  def flush
    collection.drop
  end
  alias :clean :flush

  # flush expired caches if cleanup hasn't been run recently
  def flush_expired 
    if !@cleanup_last.nil? && !@options[:cleanup_life].nil? && (@cleanup_last+@options[:cleanup_life]) < Time.now
      flush_expired!
    end
  end

  # flush expired caches, ingoring when garbage collection was last run
  # update indexes
  def flush_expired!
    # commenting out forking until I'm sure it's necessary
    # and won't cause zombie processes
    #gcpid = Process.fork do
      collection.remove(expires: {'$lt' => Time.now})
      unless @ensure_indexes
        collection.ensure_index([[:tags, 1]])
        collection.ensure_index([[:expires, -1]])
      end
      @cleanup_last = Time.now
    #end
    #Process.detach(gcpid)
  end
  alias :clean_expired :flush_expired!

  # create or read cache
  # - creates cache if it doesn't exist
  # - reads cache if it exists
  def save id, tags = [], ttl = @options[:lifetime]
    begin
      doc = collection.find_one(_id: id, expires: { '$gt' => Time.now })
      return deserialize(doc['data']) unless doc.nil?

      data = Proc.new { yield }.call
      collection.save({
        _id:      id,
        data:     serialize(data),
        tags:     tags,
        expires:  calc_expires(ttl)
      })
      return data

    rescue LocalJumpError
      # when nothing is passed to yield and it's called
      return nil
    end
  end
  alias :cache :save 

  # set cache
  # - creates cache if it doesn't exist
  # - updates cache if it does exist
  def set id, data, tags = [], ttl = @options[:lifetime]
    collection.save({
      _id:      id,
      data:     serialize(data),
      tags:     tags,
      expires:  calc_expires(ttl)
    })
    flush_expired if @options[:cleanup_auto]
    true
  end
  alias :replace :set    # for memcached compatability

  # add cache
  # - creates cache if it doesn't exist
  # - return false if it does
  def add id, data, tags = [], ttl = @options[:lifetime]
    begin
      collection.insert({
        _id:      id,
        data:     serialize(data),
        tags:     tags,
        expires:  calc_expires(ttl)
      }, safe: true)
    rescue Mongo::OperationFailure
      flush_expired if @options[:cleanup_auto]
      return false
    end
    flush_expired if @options[:cleanup_auto]
    return true
  end

  # get cache
  # - reads cache if it exists and isn't expired or raises Diskcache::NotFound
  # - if passed an Array returns only items which exist and aren't expired, it raises Diskcache::NotFound if none are available
  def get id
    flush_expired if @options[:cleanup_auto]
    if id.is_a? Array
      # TODO: more mongo'y way to do this, perhaps a map/reduce?
      # STORE.find({ _id: {'$in' => ['no1', 'no2', 'no3']}})
      hash = {}
      id.each do |i|
        doc = collection.find_one(_id: i)
        if !doc.nil? && doc['expires'] > Time.now
          hash[i] = deserialize(doc['data']) 
        end
      end
      return hash unless hash.empty?
    else
      doc = collection.find_one(_id: id)
      if !doc.nil? && doc['expires'] > Time.now
        return deserialize(doc['data']) 
      end
    end
    raise Mongocached::NotFound 
  end
  alias :load :get

  private
  def serialize data
    if @options[:automatic_serialization]  
      Marshal::dump(data) 
    else
      data
    end
  end

  def deserialize data
    if @options[:automatic_serialization]  
      Marshal::load(data) 
    else
      data
    end
  end

  def calc_expires ttl = @options[:lifetime]
    return nil if ttl.nil?
    Time.now+ttl
  end

  def collection
    @collection ||= db[@options[:collection]]
  end

  def db
    unless @db
      @db = connection[@options[:dbname]]
      if @options.has_key?(:username) and @options.has_key?(:password) 
        @db.authenticate(@options[:username], @options[:password])
      end
    end
    @db
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
