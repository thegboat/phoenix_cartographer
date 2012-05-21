module PhoenixCartographer
  class MapLocation
    
    attr_reader :lat, :lon
    
    def initialize(coordinates)
      @lat = coordinates.lat
      @lon = coordinates.lon
      @proxy = []
    end
    
    alias :latitude :lat
    alias :longitude :lon
    
    #how to gently turn me into json
    def to_json(options = {})
      {
        :lat => lat,
        :lon => lon,
        :data => proxy
      }.to_json
    end
    
    #we keep track of our objects at this location
    def <<(val)
      proxy << val
    end
    
    def count
      proxy.length
    end
    
    private
    
    #our array of objects at this location
    attr_reader :proxy
    
  end
end