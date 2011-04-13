# super-simple memory cache. if the key is found in cache,
# it is returned. Otherwise it stores the result of the code
# block supplied, which should do the actual getting of the data
# you want.
module SSO
class MemoryCache

   @@caches = {}    

   # Initialize this named cache. If you create another cache
   # with the same name it will use the same store from memory.
   def initialize(name)
      @cache = @@caches[name] ||= {}
      @logger = RAILS_DEFAULT_LOGGER # rails dependency
   end

   # caches the provided code block.
   def cached(key, max_age=0)
      (raise ArgumentError, "need a block") unless block_given?
      # if the API URL exists as a key in cache, we just return it
      # we also make sure the data is fresh
      if @cache.has_key? key
          if Time.now-@cache[key][0]<max_age 
             @logger.debug("Cache entry '#{key}' found!")
             return @cache[key][1]
          else
             @logger.debug("Cache entry '#{key}' expired")
             @cache.delete(key)
          end
      else
          @logger.debug("No cache entry for '#{key}'")
      end
      result = yield
      @cache[key] = [Time.now, result]
      result
   end

end
end
