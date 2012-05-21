require 'rubygems'
require 'ostruct'

require 'phoenix_cartographer'



class TestObject < OpenStruct
  
  attr_accessor :coordinates
  
  def initialize(lat,lon, options = {})
    super(options)
    @coordinates = PhoenixCartographer::Coordinates.new(lat,lon)
  end
end

class TestMap < PhoenixCartographer::Map
  
  private

  def marker_unique_by
    current_object.unique_by
  end

  def icon_chooser
    current_object.color
  end

  def build_node
    "i am a node of object #{current_object.object_id}"
  end
end