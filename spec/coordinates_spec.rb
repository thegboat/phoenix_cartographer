require 'spec_helper'

describe PhoenixCartographer::Coordinates do
  
  
  describe "latitude=, longitude=" do
    it "should set latitude/longitude to nil or BigDecimal evaluation" do
      coords = PhoenixCartographer::Coordinates.new(nil,nil)
      coords.latitude.should eq(nil)
      coords.longitude.should eq(nil)
      coords.latitude = 1
      coords.latitude.is_a?(BigDecimal).should eq(true)
      coords.latitude.should eq(BigDecimal('1'))
      coords.longitude = 1
      coords.longitude.is_a?(BigDecimal).should eq(true)
      coords.longitude.should eq(BigDecimal('1'))
    end
  end
  
  describe "empty?, blank?" do
    it "should be true when latitude or longitude is nil" do
      coords = PhoenixCartographer::Coordinates.new(nil,nil)
      coords.empty?.should eq(true)
      coords.blank?.should eq(true)
      coords = PhoenixCartographer::Coordinates.new(0,nil)
      coords.empty?.should eq(true)
      coords.blank?.should eq(true)
      coords = PhoenixCartographer::Coordinates.new(nil,0)
      coords.empty?.should eq(true)
      coords.blank?.should eq(true)
    end
  end
  
  describe "empty?, blank?" do
    it "should be false when latitude and longitude are not nil" do
      coords = PhoenixCartographer::Coordinates.new(0,0)
      coords.empty?.should eq(false)
      coords.blank?.should eq(false)
    end
  end
  
  describe "present?" do
    it "should be true when latitude and longitude are not nil" do
      coords = PhoenixCartographer::Coordinates.new(0,0)
      coords.present?.should eq(true)
    end
  end
  
  describe "present?" do
    it "should be false when latitude or longitude is nil" do
      coords = PhoenixCartographer::Coordinates.new(nil,nil)
      coords.present?.should eq(false)
      coords = PhoenixCartographer::Coordinates.new(0,nil)
      coords.present?.should eq(false)
      coords = PhoenixCartographer::Coordinates.new(nil,0)
      coords.present?.should eq(false)
    end
  end
  
  describe "[], []=" do
    it "should allow coordinate values to be accessed as an array" do
      coords = PhoenixCartographer::Coordinates.new(0,1)
      coords[0].should eq(0)
      coords[1].should eq(1)
      coords[-2].should eq(0)
      coords[-1].should eq(1)
      coords[0] = 1
      coords[0].should eq(1)
      coords[1] = 0
      coords[1].should eq(0)
      lambda { coords[2] }.should raise_error(RangeError)
      lambda { coords[-3] }.should raise_error(RangeError)
    end
  end
  
  describe "-" do
    it "should return the distance between two coordinates" do
      lat_lon = [2,2]
      coords1 = PhoenixCartographer::Coordinates.new(0,0)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      (coords1 - coords2).should eq(PhoenixCartographer.distance(0,0,*lat_lon))
      (coords1 - lat_lon).should eq(PhoenixCartographer.distance(0,0,*lat_lon))
    end
    
    it "should return nil coordinates are empty" do
      lat_lon = [nil,2]
      coords1 = PhoenixCartographer::Coordinates.new(0,0)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      coords2.empty?.should eq(true)
      (coords1 - coords2).should eq(nil)
      (coords1 - lat_lon).should eq(nil)
    end
  end
      
  describe "to_a" do
    it "should return [lat,lon] of Cooridnates object" do
      coords = PhoenixCartographer::Coordinates.new(0,1)
      coords.to_a.should eq([BigDecimal('0'), BigDecimal('1')])
    end
  end
  
  describe "in?" do
    it "should be true when coordinates are in range" do
      lat_lon = [1,1]
      dist = PhoenixCartographer.distance(0,0,2,2)
      coords1 = PhoenixCartographer::Coordinates.new(0,0)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      coords1.in?(coords2, dist).should eq(true)
      coords1.in?(lat_lon, dist).should eq(true)
    end
    
    it "should be false when coordinates are not in range" do
      dist = PhoenixCartographer.distance(0,0,1,1)
      coords1 = PhoenixCartographer::Coordinates.new(0,0)
      coords2 = PhoenixCartographer::Coordinates.new(2,2)
      coords1.in?(coords2, dist).should eq(false)
      coords1.in?(2,2, dist).should eq(false)
    end
    
    it "should error when the arguments are invalid" do
      coords1 = PhoenixCartographer::Coordinates.new(0,0)
      lambda { coords1.in?(1,1,100,1) }.should raise_error(ArgumentError)
      lambda { coords1.in?(1,1) }.should raise_error(ArgumentError)
    end
  end
    
  describe "==, eql?" do
    it "should be true when lat and lon are the same" do
      lat_lon = [2,2]
      coords1 = PhoenixCartographer::Coordinates.new(*lat_lon)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      (coords1 == coords2).should eq(true)
      (coords1 == lat_lon).should eq(true)
      (coords1.eql?(coords2)).should eq(true)
      (coords1.eql?(lat_lon)).should eq(true)
    end
    
    it "should be false when lat and lon are not the same" do
      lat_lon = [2,2]
      coords1 = PhoenixCartographer::Coordinates.new(1,1)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      (coords1 == coords2).should eq(false)
      (coords1 == lat_lon).should eq(false)
      (coords1.eql?(coords2)).should eq(false)
      (coords1.eql?(lat_lon)).should eq(false)
    end
  end
  
  describe "hash, eql?" do
    it "should recognize equal coordinates as the same key in a hash" do
      lat_lon = [2,2]
      hash = {}
      coords1 = PhoenixCartographer::Coordinates.new(*lat_lon)
      coords2 = PhoenixCartographer::Coordinates.new(*lat_lon)
      hash[coords1].should eq(nil)
      hash[coords1] = 'value'
      hash[coords2].should eq('value')
      hash.has_key?(coords2).should eq(true)
    end
  end
end