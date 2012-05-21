require 'spec_helper'

describe PhoenixCartographer do
  
  describe "distance method" do
    # values from http://www.csgnetwork.com/gpsdistcalc.html
    it "should calculate distance in miles closely" do
      results = []
      results << (PhoenixCartographer.distance(0,0,1,1) - 97.6461391111182).abs
      results << (PhoenixCartographer.distance(0,0,45,45) - 4142.879999054057).abs
      results << (PhoenixCartographer.distance(0,0,90,90) - 6214.319998581088).abs
      results.all? {|r| r < 0.0001}.should eq(true)
    end
    
    it "should calculate distance in kms closely" do
      results = []
      results << (PhoenixCartographer.distance(0,0,1,1, :km) - (97.6461391111182 * 1.609344)).abs
      results << (PhoenixCartographer.distance(0,0,45,45, :km) - (4142.879999054057 * 1.609344)).abs
      results << (PhoenixCartographer.distance(0,0,90,90, :km) - (6214.319998581088 * 1.609344)).abs
      results.all? {|r| r < 0.0001}.should eq(true)
    end
  end
  
  describe "to_bigdec" do
    it "should return a bigdecimal with a valid argument" do
      PhoenixCartographer.to_bigdec("5").is_a?(BigDecimal).should eq(true)
    end
    
    it "should return an array of bigdecimal with valid arguments" do
      rtn = PhoenixCartographer.to_bigdec("5", 0.1, 5)
      rtn.is_a?(Array).should eq(true)
      rtn.all? {|n| n.is_a?(BigDecimal)}.should eq(true)
    end
    
    it "should return a nil with a nil argument" do
      PhoenixCartographer.to_bigdec(nil).nil?.should eq(true)
    end
  end
  
  describe "to_rad" do
    it "should convert degrees to radians correctly" do
      results = []
      results << (PhoenixCartographer.to_rad(180) - Math::PI).abs
      results << (PhoenixCartographer.to_rad(-90) + Math::PI/2).abs
      results << (PhoenixCartographer.to_rad(90) - Math::PI/2).abs
      results << (PhoenixCartographer.to_rad(45) - Math::PI/4).abs
      results << PhoenixCartographer.to_rad(0).abs
      results.all? {|r| r < 0.0001}.should eq(true)
    end
  end
  
  describe "to_deg" do
    it "should convert degrees to radians correctly" do
      results = []
      results << (PhoenixCartographer.to_deg(Math::PI) - 180).abs
      results << (PhoenixCartographer.to_deg(-Math::PI/2) + 90).abs
      results << (PhoenixCartographer.to_deg(Math::PI/2) - 90).abs
      results << (PhoenixCartographer.to_deg(Math::PI/4) - 45).abs
      results << PhoenixCartographer.to_deg(0).abs
      results.all? {|r| r < 0.0001}.should eq(true)
    end
  end
  
  describe "quiet_timeout" do
    it "should timeout quietly" do
      PhoenixCartographer.quiet_timeout(1) { sleep(1.2) }.should eq(nil)
    end
    
    it "should return default and no error on timeout" do
      PhoenixCartographer.quiet_timeout(1, "default") { sleep(1.2) }.should eq("default")
    end
    
    it "should error when instructed" do
      lambda { PhoenixCartographer.quiet_timeout(1, Timeout::Error) { sleep(1.2) } }.should raise_error(Timeout::Error)
    end
  end
  
  describe "random_point_from" do
    it "should create a point within the correct distance" do
      p = PhoenixCartographer.random_point_from(0,0, 10)
      rtn = PhoenixCartographer.distance(0,0, p[0], p[1])
      (rtn <= 10).should eq(true)
      (rtn > 0).should eq(true)
    end
  end
  
  describe "geocode" do
    it "should geocode closely" do
      rtn = PhoenixCartographer.geocode(29646)
      rtn.concat([34.1465789, -82.1496049])
      (PhoenixCartographer.distance(*rtn) < 5).should eq(true)
    end
  end
  
end