require 'benchmark'
require 'diskcached'
#require 'mongocached'
require '../lib/mongocached'
require 'memcached'

# init diskcached
diskcache = Diskcached.new('/tmp/bm_cache') 

# init mongocached with defaults -- localhost
mongocache = Mongocached.new()

# init memcached
memcache = Memcached.new("localhost:11211")

# create a data object to be cached
cache_content = "some string to be saved in cached"

# set the number of times to itterate over the cache get
#   I do this because these actions are very fast, so a 
#   single call, isn't really enough to show a difference.
# 
#   For this, I typically use 100,000, as it allows you to 
#   easily translate all interations into a single 
#   intteration. 
#   
#   1 second for all, is 1 microsecond for a single itteration
#   using "fuzzy logic".
itterations = 100000

# set each cache, so we have something to get
diskcache.set("bm_key", cache_content)
mongocache.set("bm_key", cache_content)
memcache.set("bm_key", cache_content)

# now for the meat
Benchmark.bm do |bm|
  # first report - diskcached
  bm.report('disk') do
    (1..itterations).each do
      diskcache.get("bm_key") 
    end
  end
  
  # second report - mongocached
  bm.report('mong') do
    (1..itterations).each do
      mongocache.get("bm_key") 
    end
  end
  
  # third report - memcached
  bm.report('memc') do
    (1..itterations).each do
      mongocache.get("bm_key") 
    end
  end
end

