module PhoenixCartographer
  class Map
    
    attr_reader :objects, :name, :zoom, :visible_tag, :scrollwheel
    attr_writer :style
    
    #name - name of the map ... used to name DOM element as well
    #objects - array of objects that responds to coordinates where coordinates is an array [lat,lon] or coordinates object
    def initialize(name, objects, opts = {})
      @name = name
      @zoom      = opts[:zoom] || :bound
      @objects = objects
      @style = opts[:style]
      @built = false
      self.visible_tag = opts[:visible_tag] if opts[:visible_tag]
      @scrollwheel = !!opts[:scrollwheel]
      @tags = {}
      @locations = {}
      @marker_nodes = []
      @marker_counter = "0"
      self.size = opts[:size] || [1000,600]
    end
    
    class << self

      #some header code required for every map ... minified
      # <script src="http://google-maps-utility-library-v3.googlecode.com/svn/trunk/markermanager/src/markermanager_packed.js" type="text/javascript"></script>
      # <script src="http://google-maps-utility-library-v3.googlecode.com/svn/trunk/markerclusterer/src/markerclusterer_packed.js" type="text/javascript"></script>
      def header
        @header ||= %{\n<!--[if IE]>\n<style type="text/css">v\\:* { behavior:url(#default#VML); }</style>\n<![endif]-->
          <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
          <script src="/javascripts/phoenix_cartographer.js" type="text/javascript"></script>
        }.minified!
      end
      
    end
    
    #build locations and data to pass to javascript
    def build
      objects.each do |@current_object|
        coords = current_object.coordinates
        if coords.is_a?(Array)
          coords = current_object.coordinates = PhoenixCartographer::Coordinates.new(*coords)
        elsif !coords.is_a?(PhoenixCartographer::Coordinates)
          next
        end
        next if coords.empty?
        locations[coords] ||= MapLocation.new(coords)
        locations[coords] << new_marker
        adjust_points
      end
      @built = true
    end
    
    #add a tag; tagging enables visiblity functions
    #tag_method should be a method that all objects respond to
    def add_tag(tag_method, tag_chooser = {})
      raise(ArgumentError, "tag chooser should be a Hash like object") unless tag_chooser.is_a?(Hash)
      tags.merge!(tag_method => tag_chooser)
      tags
    end
    
    #all the html required to display map
    #use in view code
    def to_s
      build unless @built
      [
        self.class.header,
        initializer_function,
        map_div_html,
        marker_nodes_to_html
      ].compact.join(" ")
    end
    
    def visible_tag=(val)
      if @visible_tag
        @visible_tag << val
      else
        @visible_tag = [val]
      end
      @visible_tag.flatten!
      val
    end

    #set the map size
    def size=(val)
      v = val.is_a?(Array)
      v &&= val.length == 2
      v &&= val.all? {|item| item.to_s =~ /^\d+$/ }
      raise InvalidSize unless v
      @width = val.first.to_i
      @height = val.last.to_i
    end

    def size
      width and height ? [width , height] : [1000,600]
    end

    #we may want to style the map later
    def style
      "#{width}px;height:#{height}px;#{@style}"
    end
    
    private 
    
    attr_reader :width, :height, :marker_nodes, :current_object, :marker_counter
    attr_reader :center, :sw, :ne, :locations

    #a placeholder for the map on the webpage
    def map_div_html
      %{<div style="#{style}" id="#{name}" > [Map]</div>}
    end
    
    #all the data we need to provide phoenix_cartographer.js to construct the map
    def options_to_json
      build unless @built
      {
        :zoom => zoom,
        :bounds => [[sw.lat,sw.lon],[ne.lat,ne.lon]],
        :center => center.to_a,
        :scrollwheel => scrollwheel,
        :locations => locations.values,
        :visible_tag => visible_tag
      }.to_json
    end
    
    def marker_nodes_to_html
      "<div style='display:none'>#{marker_nodes.join(" ")}</div>"
    end
    
    #prepare a hash that will be converted to json to represent a new marker
    def new_marker
      marker_counter.succ!
      marker_tags = []
      
      marker_icon = icon_chooser
      marker_name = "mrk_#{marker_counter}"
      marker_tags << marker_icon
      
      tags {|tag| marker_tags << tag}

      info = build_node.gsub("\n", "<br />").minified!
      marker_nodes << %{<p id="#{marker_name}">#{info}</p>}

      rtn = {:name => marker_name, :icon => marker_icon, :tags => marker_tags}
      rtn[:uniq] = marker_unique_by if marker_unique_by
      rtn
    end
    
    def tags
      #just return tags when we dont have a block
      return @tags unless block_given?
      #if we have a block cycle through our tags for the current object
      @tags.each do |tag, chooser|
        #if the tag_method was a Proc send it the current_object
        res = if tag.is_a?(Proc)
          tag.call(current_object)
        elsif current_object.respond_to?(tag)
          current_object.send(tag)
        else
          raise ArgumentError, "one or more objects did not respond to tag method '#{tag}'"
        end
        #the default is the result of the method
        yield chooser.fetch(res,res)
      end
    end

    #lets adjust our essential map coordinates
    def adjust_points
      coords = current_object.coordinates
      if sw and ne
        @sw.lat = coords.lat if sw.lat > coords.lat
        @sw.lon = coords.lon if sw.lon > coords.lon
        @ne.lat = coords.lat if ne.lat < coords.lat
        @ne.lon = coords.lon if ne.lon < coords.lon
        @center.lat = (ne.lat - sw.lat )/2 + sw.lat
        @center.lon = (ne.lon - sw.lon )/2 + sw.lon
      else
        @sw = coords.dup
        @ne = coords.dup
        @center = coords.dup
      end
      
      true
    end

    #override this method in your custom map to choose icons
    def icon_chooser
      "red"
    end

    #override this method in your custom map to build info window content
    def build_node
      ""
    end
    
    #override this method to influence the counter on numbered icons
    #the number reflected will count each unique object; this method tells us how unique is defined
    def marker_unique_by
      nil
    end
    
    #instructs the onload event to create our map
    #map_options is all the data we need
    #then we add our map initializer to onload function
    def initializer_function
      %{<script type="text/javascript">
        var map_options = #{options_to_json};
        onload_before_#{name} = typeof window.onload == 'function' ? window.onload : function(){};
        window.onload = function(){
          onload_before_#{name};
          phoenix_cartographer.init_map('#{name}', map_options);
          map_options = null;
        }
      </script>
      }.minified!
    end
  end

end