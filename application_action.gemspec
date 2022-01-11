$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "application_action/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "application_action"
  spec.version     = ApplicationAction::VERSION
  spec.authors     = ["Rudiney Altair Franceschi"]
  spec.email       = ["rudi.atp@gmail.com"]
  spec.homepage    = "https://github.com/Rudiney/application_action"
  spec.summary     = "Adds the 'Actions' concept to your Rails APP"
  spec.description = "The 'Actions' concept can help you move logic out from Controllers & Models"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry"
end
