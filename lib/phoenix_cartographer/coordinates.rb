module PhoenixCartographer
  
  class Coordinates
    
    attr_reader :latitude, :longitude

    def initialize(lat,lon)
      self.latitude, self.longitude = [lat,lon]
    end
    alias :lat :latitude
    alias :lon :longitude
    
    def latitude=(val)
      val = PhoenixCartographer.to_bigdec(val)
      @latitude = val && val.round(7)
    end
    
    def longitude=(val)
      val = PhoenixCartographer.to_bigdec(val)
      @longitude = val && val.round(7)
    end
    alias :lat= :latitude=
    alias :lon= :longitude=
    
    #equality and usage as a key in a hash require this
    def ==(val)
      to_a == val.to_a
    end
    alias :eql? :==
    
    #usage as a key in a hash requires this
    def hash
      to_a.hash
    end
    
    #string representation
    def to_s
      empty? ? "" : "(#{latitude}, #{longitude})"
    end
    alias :inspect :to_s
    
    #url friendly representation
    def to_param
      empty? ? "" : "#{latitude},#{longitude}"
    end
    
    def [](idx)
      raise(RangeError, "Coordinates can only have two values") unless (-2..1).include?(idx)
      to_a[idx]
    end
    
    def []=(idx,val)
      raise(RangeError, "Coordinates can only have two values") unless (-2..1).include?(idx)
      tmp = to_a; tmp[idx] = val;
      self.latitude, self.longitude = tmp
    end
    
    #when we need coordinates as an array
    def to_a
      [latitude,longitude]
    end
    
    #the coordinates are set
    def present?
      !!(latitude and longitude)
    end
    
    #the coordinates are not set
    def empty?
      !present?
    end
    alias :blank? :empty?

    #val is another Coordinates object
    #coordinates1 - coordinates2 will yield the distance
    def -(val)
      args = to_a + val.to_a
      return if args.any?(&:nil?)
      PhoenixCartographer.distance(*args)
    end
    
    #takes (coordinates, radius) or ...
    #(lat, lon, radius)
    #answers the question are the two point within a certain distance
    #ex : coordinates.in?(coordinates2, 5) where radius (5) is in miles
    def in?(*args)
      args.flatten!
      if args.length == 2 and args.first.is_a?(PhoenixCartographer::Coordinates)
        lat, lon, radius = (args.first.to_a << args.last)
      elsif args.length == 3
        lat, lon, radius = args
      else
        raise ArgumentError, "Coordinates#in? takes coordinates and a radius as arguments"
      end
        
      radius > PhoenixCartographer.distance(latitude, longitude, lat, lon)
    end
    
  end
  
end