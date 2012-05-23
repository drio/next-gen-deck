require 'json'

class MockRedis
  def initialize
    @h = {}
  end

  def[](key)
    @h[key]
  end

  def set(key, val)
    @h[key] = JSON.parse
  end
end
