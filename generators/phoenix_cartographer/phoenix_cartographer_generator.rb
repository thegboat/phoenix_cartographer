class PhoenixCartographerGenerator < Rails::Generator::Base
      
  def manifest
    record do |m|
      m.template("phoenix_cartographer.js", "public/javascripts/phoenix_cartographer.js", :chmod => 0755)
      m.directory("public/images/phoenix_cartographer/numbers")
      0.upto(9) do |n|
        m.template("red_#{n}.png", "public/images/phoenix_cartographer/numbers/red_#{n}.png", :chmod => 0644)
      end
    end
  end
  
end