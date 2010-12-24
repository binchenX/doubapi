# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "doubapi/version"

Gem::Specification.new do |s|
  s.name        = "doubapi"
  s.version     = Doubapi::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["pierr chen"]
  s.email       = ["pierr.chen@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{douban API gems}
  s.description = %q{douban API gems}

  s.rubyforge_project = "doubapi"
  s.add_development_dependency "rspec", "~> 2.0.0.beta.22"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
