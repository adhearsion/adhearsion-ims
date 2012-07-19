# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion-ims/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion-ims"
  s.version     = Adhearsion::IMS::VERSION
  s.authors     = ["Jason Goecke"]
  s.email       = ["jason@goecke.net"]
  s.homepage    = "http://adhearsion.com"
  s.summary     = "Adhearsion IMS Integration"
  s.description = "Provides convenience methods when using Adhearsion with Rayo for IP Multimedia Subsystem (IMS) integration. Specifically ISC triggers."

  s.rubyforge_project = "adhearsion-ims"

  # Use the following if using Git
  # s.files         = `git ls-files`.split("\n")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.files         = Dir.glob("{lib}/**/*") + %w( README.md Rakefile Gemfile)
  s.test_files    = Dir.glob("{spec}/**/*")
  s.require_paths = ["lib"]

  s.add_runtime_dependency %q<adhearsion>, ["~> 2.0"]
  s.add_runtime_dependency %q<activesupport>, ["~> 3.0"]

  s.add_development_dependency %q<bundler>, ["~> 1.0"]
  s.add_development_dependency %q<rspec>, ["~> 2.5"]
  s.add_development_dependency %q<ci_reporter>, ["~> 1.6"]
  s.add_development_dependency %q<simplecov>, [">= 0"]
  s.add_development_dependency %q<simplecov-rcov>, [">= 0"]
  s.add_development_dependency %q<yard>, ["~> 0.6"]
  s.add_development_dependency %q<rake>, [">= 0"]
  s.add_development_dependency %q<mocha>, [">= 0"]
  s.add_development_dependency %q<guard-rspec>
 end
