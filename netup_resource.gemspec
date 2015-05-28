$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "netup_resource/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "netup_resource"
  s.version     = NetupResource::VERSION
  s.authors     = ["Michael Roeder", "Markus Kuerzinger", "Fabian Zitter"]
  s.email       = ["fabian.zitter@net-up.de"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of NetupResource."
  s.description = "TODO: Description of NetupResource."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "webmock"
end
