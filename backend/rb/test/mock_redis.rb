require 'json'

class MockRedis
  def initialize
    @h = {}
  end

  def[](key)
    JSON.parse @h[key] unless @h[key].nil?
  end

  def set(key, val)
    @h[key] = val
  end
end
