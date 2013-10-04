$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "app_status/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "app_status"
  s.version     = AppStatus::VERSION
  s.authors     = ["Alex Dean"]
  s.email       = ["alex@crackpot.org"]
  s.homepage    = "http://github.com/alexdean/app_status"
  s.summary     = "AppStatus is a Rails engine for exposing app data to Nagios.."
  s.description = "AppStatus provides a URL which is easily consumable by Nagios or other monitoring tools."

  s.files = Dir["{app,bin,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "haml"
  s.add_dependency "haml-rails"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails", "~> 2.6"
  s.add_development_dependency "timecop"
end
