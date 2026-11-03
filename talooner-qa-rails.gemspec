# frozen_string_literal: true

require_relative "lib/talooner_qa/version"

Gem::Specification.new do |spec|
  spec.name = "talooner-qa-rails"
  spec.version = TaloonerQa::VERSION
  spec.authors = ["Talooner"]
  spec.email = ["dev@talooner.com"]

  spec.summary = "The /__qa hooks Talooner QA tests a Rails app through"
  spec.description = "A Rails engine serving the test-only /__qa/* API that talooner-qa drives: " \
                     "roles, pages from the router, seeds from FactoryBot or your own seed script, " \
                     "login as a role, reset, feature flags and backend checks."
  spec.homepage = "https://github.com/Talooner/talooner-qa-rails"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "app/**/*.rb", "config/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.2"
  spec.add_dependency "railties", ">= 7.2"
end
