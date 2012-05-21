require 'spec_helper'

describe PhoenixCartographer::Map do
  
  describe "configuration" do
    
    before(:each) do
      @map = PhoenixCartographer::Map.new("my_map", [])
    end
  
    describe "initialize" do
      it "should set options correctly" do
        @map.size.should eq([1000,600])
        (@map.send(:style) =~ /display:none/).should eq(nil)
        @map.send(:visible_tag).should eq(nil)
        @map.zoom.should eq(:bound)
      
        map = PhoenixCartographer::Map.new("my_map", [],
          :zoom => 5,
          :style => "display:none",
          :visible_tag => "name",
          :size => [100,100]
        )
      
        map.size.should eq([100,100])
        (!!(map.style =~ /display:none/)).should eq(true)
        map.send(:visible_tag).should eq(["name"])
        map.zoom.should eq(5)
      end
    end
  
    describe "add_tag" do
      it "should add a tag to the map" do
        @map.add_tag(:some_method)
        @map.send(:tags).should eq(:some_method => {})
        @map.add_tag(:another_method, {true => 'white'})
        @map.send(:tags).should eq(:some_method => {}, :another_method => {true => 'white'})
      end
    
      it "should raise an error when tag_chooser (arg 2) is not a hash" do
        lambda { @map.add_tag(:some_method, 'wrong_arg')}.should raise_error(ArgumentError)
      end
    end
  
    describe "visible_tag=" do
      it "should add visiblity tags" do
        @map.visible_tag = "tag1"
        @map.send(:visible_tag).should eq(["tag1"])
        @map.visible_tag = "tag2"
        @map.send(:visible_tag).should eq(["tag1", "tag2"])
      end
    end
    
    describe "size=" do
      it "should set size correctly" do
        @map.size.should eq([1000,600])
        @map.size = [100,100]
        @map.size.should eq([100,100])
      end
      
      it "should raise an error when invalid sizes are set" do
        lambda { @map.size = "bad size" }.should raise_error(PhoenixCartographer::InvalidSize)
      end
    end
  end
  
  describe "building data" do
    
    before(:each) do
      
      objects = [
        TestObject.new(0,0, :color => 'red', :unique_by => '1', :some_method => 'first', :another_method => true),
        TestObject.new(0,0, :color => 'blue', :unique_by => '1', :some_method => 'second', :another_method => false),
        TestObject.new(0,0, :color => 'yellow', :unique_by => '2', :some_method => 'third', :another_method => false),
        TestObject.new(1,1, :color => 'red', :unique_by => '2', :some_method => 'fourth', :another_method => true)
      ]
      @map = TestMap.new("my_map", objects)
      @map.add_tag(lambda {|obj| obj.some_method })
      @map.add_tag(:another_method, true => 'good', false => 'bad')
      @map.visible_tag = 'red'
    end
    
    describe "build" do
      
      it "should group objects of a single location" do
        @map.build
        @map.send(:locations).length.should eq(2)
        @map.send(:locations)[PhoenixCartographer::Coordinates.new(0,0)].count.should eq(3)
        @map.send(:locations)[PhoenixCartographer::Coordinates.new(1,1)].count.should eq(1)
        
      end
      
      it "should tag object correctly" do
        @map.build
        data1 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(0,0)]
        data1.send(:proxy)[0][:tags].sort.should eq(['red', 'first', 'good'].sort)
        data1.send(:proxy)[1][:tags].sort.should eq(['blue', 'second', 'bad'].sort)
        data1.send(:proxy)[2][:tags].sort.should eq(['yellow', 'third', 'bad'].sort)
        data2 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(1,1)]
        data2.send(:proxy)[0][:tags].sort.should eq(['red', 'fourth', 'good'].sort)
      end
      
      it "should choose color correctly" do
        @map.build
        data1 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(0,0)]
        data1.send(:proxy)[0][:icon].should eq('red')
        data1.send(:proxy)[1][:icon].should eq('blue')
        data1.send(:proxy)[2][:icon].should eq('yellow')
        data2 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(1,1)]
        data2.send(:proxy)[0][:icon].should eq('red')
      end
      
      it "should choose unique tag correctly" do
        @map.build
        data1 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(0,0)]
        data1.send(:proxy)[0][:uniq].should eq('1')
        data1.send(:proxy)[1][:uniq].should eq('1')
        data1.send(:proxy)[2][:uniq].should eq('2')
        data2 = @map.send(:locations)[PhoenixCartographer::Coordinates.new(1,1)]
        data2.send(:proxy)[0][:uniq].should eq('2')
      end
      
      it "should choose significant points correctly" do
        @map.build
        @map.send(:sw).to_a.should eq([0,0])
        @map.send(:ne).to_a.should eq([1,1])
        @map.send(:center).to_a.should eq([0.5,0.5])
      end
      
      it "should set built variable when build is complete" do
        @map.build
        @map.instance_variable_get('@built').should eq(true)
      end
      
      it "should set js options correctly" do
        opts = @map.send(:options_to_json)
        opts = JSON.parse(opts)
        opts['zoom'].should eq('bound')
        opts['bounds'].should eq( [["0.0", "0.0"], ["1.0", "1.0"]])
        opts['center'].should eq(['0.5','0.5'])
        (!!opts['scrollwheel']).should eq(false)
        opts['visible_tag'].should eq(['red'])
      end
    end
  end
  
end