
require "phoenix_cartographer/version"
require "json"
require 'active_support'
require 'active_support/core_ext.rb'
require "rest_client"
require "bigdecimal"
require "phoenix_cartographer/core_ext"
require "phoenix_cartographer/map"
require "phoenix_cartographer/errors"
require "phoenix_cartographer/coordinates"
require "phoenix_cartographer/map_location"


module PhoenixCartographer
  GREAT_CIRCLE = 3956.15898291568

  class << self

    #distance formula
    def distance( lat1, lon1, lat2, lon2, output = nil)
      lat1, lon1, lat2, lon2 = to_bigdec(lat1, lon1, lat2, lon2)

      dlon_rad, dlat_rad = to_rad( lon2 - lon1, lat2 - lat1 )
      lat1_rad, lon1_rad, lat2_rad, lon2_rad = to_rad(lat1, lon1, lat2,lon2)

      a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
      c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))

      dMi = GREAT_CIRCLE * c

      case output
      when :km
        dMi * 1.609344
      when :metric
        km = (dMi * 1.609344).floor
        m = (((dMi * 1.609344) - km) * 1000).round
        rtn = km > 0 ? "#{km} km " : ""
        "#{rtn}#{m} m"
      when :std
        m = dMi.floor
        y = ((dMi - m) * 1760).round
        rtn = m > 0 ? "#{m} mi " : ""
        "#{rtn}#{y} yd"
      else dMi
      end
    end

    # random point within "rds" miles of "lat","lon"
    # used to randomize address locations
    def random_point_from(lat, lon, rds = 10)
      # if either of these is nil we need to return
      return [nil, nil] if lat.nil? || lon.nil?

      lat, lon = to_rad(lat, lon)
      hdg = rand(361)
      rds = [rds.to_i ,1 ].max * 1000
      rds = (rand(rds)/1000.0) + 0.1

      end_lat = Math.asin(Math.sin(lat)*Math.cos(rds/GREAT_CIRCLE) +
                        Math.cos(lat)*Math.sin(rds/GREAT_CIRCLE)*Math.cos(hdg))

      end_lon = lon+Math.atan2(Math.sin(hdg)*Math.sin(rds/GREAT_CIRCLE)*Math.cos(lat),
                             Math.cos(rds/GREAT_CIRCLE)-Math.sin(lat)*Math.sin(end_lat))

      [to_deg(end_lat), to_deg(end_lon)]
    end

    #turn radians to degress
    def to_rad(*degrees)
      rtn = degrees.map do |v|
        v = to_bigdec(v)
        to_bigdec(v / 180.0 * Math::PI)
      end
      rtn.length < 2 ? rtn.first : rtn
    end

    #turn degress to radians
    def to_deg(*rads)
      rtn = rads.map do |v|
        v = to_bigdec(v)
        to_bigdec(v * 180.0 / Math::PI).round(7)
      end
      rtn.length < 2 ? rtn.first : rtn
    end

    #change values to BigDecimal
    #nil values will not be changed
    # 1.8.7-p302 :002 > PhoenixCartographer.to_bigdec(9.9,"9.9")
    #  => [#<BigDecimal:100b8e6a0,'0.99E1',18(18)>, #<BigDecimal:100b8e5b0,'0.99E1',18(18)>]
    # 1.8.7-p302 :003 > PhoenixCartographer.to_bigdec(9)
    #  => #<BigDecimal:100b89218,'0.9E1',9(18)>
    # 1.8.7-p302 :004 > PhoenixCartographer.to_bigdec(nil)
    #  => nil
    def to_bigdec(*args)
      rtn = args.map do |v|
        (v.nil? or v.is_a?(BigDecimal)) ? v : BigDecimal(v.to_f.to_s)
      end
      rtn.length < 2 ? rtn.first : rtn
    end

    #secure geocoding api call
    #format can be json or xml but most of the logic in cartographer expects json
    def geocode_url(format = "json")
      "https://maps.googleapis.com/maps/api/geocode/#{format}"
    end

    #handles timeouts
    #time is the time to wait til timeout
    #default is the value to return on failure or exception to raise
    def quiet_timeout(time, default = nil)
      begin
        Timeout.timeout(time) do
          yield
        end
      rescue Timeout::Error
        if default.is_a?(Class) && default < Exception
          raise default
        else
          default
        end
      end
    end

    #performs get requests for members of cartographer module
    #wrapped by quiet timeout
    def request(url, default = nil, time = 10)
      quiet_timeout(10, default) do
        RestClient.get(url)
      end
    end

    #perform geocode on a humanized address
    def geocode(address)
      #setup params with
      #address of course
      #bounds; just says we prefer locations in carolina; just in case we had missing info
      #sensor is whether we are using a device with gps; we're not.
      params = {
        :address => address,
        :bounds => "32.1,-83.5|35.3,-78.5",
        :sensor => "false"
      }.to_param
      #make the call and parse it
      result = request("#{geocode_url}?#{params}", "{}")
      result = JSON.parse(result) rescue {}

      if result["status"] == "OK" and result["results"].size == 1
        target = result["results"][0]["geometry"]["location"]
        [target["lat"], target["lng"]]
      else
        [nil,nil]
      end
    end

    #random geocoding for tests
    def random_geocode(address)
      lat, lon = geocode(address)
      random_point_from(lat, lon)
    end

    #where to save icons
    def root_icon_directory
      RAILS_ROOT + "/public/images/phoenix_cartographer/"
    end

    #get icons from http://mapicons.nicolasmollet.com
    #hex_color is a hexadecimal color, name is what to label the color in the file system
    # iwant to add some more options but ...
    #for now called like PhoenixCartographer.get_number_icon("FFFFFF", "white")
    #this will create white icons 1-9 and a blank icon (no number)
    # the ten icons will be saved in public/images/phoenix_cartographer/numbers as white_#{number}.png
    # where white_0.png is the blank icon
    def get_number_icon(hex_color, name)
      #build the base url
      color = hex_color.gsub(/^#/, "").downcase
      name = name.underscore
      base_url = "http://mapicons.nicolasmollet.com/wp-content/uploads/mapicons/shape-default/color-"
      if color == "FFFFFF"
        base_url << "666666/shapecolor-white/shadow-1/border-dark/symbolstyle-color/symbolshadowstyle-no/gradient-bottomtop/"
      else
        base_url << color
        #we could change this values later with optional "options" argument
        base_url << "/shapecolor-color/shadow-1/border-dark/symbolstyle-white/symbolshadowstyle-dark/gradient-no/"
      end

      (0..9).to_a.each do |number|
        #this will be the file name
        file_name = "numbers/#{name}_#{number}.png"
        #finish building url
        url = %{#{base_url}#{number.to_i == 0 ? "symbol_blank" : "number_#{number}"}.png}
        #this initializes our color on the remote server if it doesnt exist
        request("http://mapicons.nicolasmollet.com/numbers-letters/?style=default&custom_color=#{color}")
        #if write succeeds, lets rest for a bit.
        sleep(0.2) if get_icon(url, file_name)
      end
    end

    #get a png file from a remote server
    #base_file_name should be a relative directory within phoenix_cartographer root directory to save as
    #if no base_file_name given the basename of the url is used
    def get_icon(url, base_file_name = nil)
      base_file_name ||= File.basename(url)
      file_name = root_icon_directory + base_file_name
      #if this file exists raise an error
      raise(IconExists, "You are trying to create an icon with a name that exists") if File.exists?(file_name)
      #fetch data and then write to file
      if src = (request(url) rescue nil)
        file = File.open(file_name, "w+")
        file.write(src)
        file.close
        puts "write of #{file_name} #{File.exists?(file_name) ? 'succeeded' : 'failed'}"
        true
      end
    end
  end
end
