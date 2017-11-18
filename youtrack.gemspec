$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "youtrack/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "youtrack"
  s.version     = Youtrack::VERSION
  s.authors     = ["maxivak"]
  s.email       = ["maxivak@gmail.com"]
  s.homepage    = "https://github.com/maxivak/youtrack"
  s.summary     = "Youtrack API client."
  s.description = "Manage Youtrack with API"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  #s.add_dependency "rails", "~> 5.1.3"

  s.add_dependency 'rest-client', ">=2.0.2"
  s.add_dependency 'httparty', ">=0.15.6"
  s.add_dependency 'rack-cors', ">=1.0.0"


  s.add_development_dependency "sqlite3"
end
