# -*- encoding: utf-8 -*-
require File.expand_path('../lib/phoenix_cartographer/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["thegboat"]
  s.email         = ["gradygriffin@gmail.com"]
  s.description   = %q{TODO: Custom javascript generator for google maps}
  s.summary       = %q{TODO: Google Map V3 api helper}
  s.homepage      = ""
  s.files         = ["lib/phoenix_cartographer/cluster_icon.rb", "lib/phoenix_cartographer/header.rb", "lib/phoenix_cartographer/icon.rb", "lib/phoenix_cartographer/infowindow.rb", "lib/phoenix_cartographer/map.rb", "lib/phoenix_cartographer/marker.rb", "lib/phoenix_cartographer/polyline.rb", "lib/phoenix_cartographer/version.rb", "lib/phoenix_cartographer.rb"]
  s.require_paths = ["lib"]
  s.test_files    = ["spec/phoenix_cartographer_spec.rb", "spec/spec_helper.rb"]
  s.name          = "phoenix_cartographer"
  s.require_paths = ["lib"]
  s.version       = PhoenixCartographer::VERSION::STRING

  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency('rails', '=2.3.4')
    s.add_runtime_dependency('json')
    s.add_runtime_dependency('rest-client', '=1.6.7')
    s.add_development_dependency("rspec")
  else
    s.add_dependency('rails', '=2.3.4')
    s.add_dependency('json')
    s.add_dependency('rest-client', '=1.6.7')
    s.add_development_dependency("rspec")
  end
end
