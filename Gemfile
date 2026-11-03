# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "factory_bot", "~> 6.5"
# CI sets RAILS_VERSION to test each supported Rails.
gem "rails", ENV.fetch("RAILS_VERSION", "~> 8.1")
gem "rspec-rails", "~> 7.0"
gem "rubocop", "~> 1.75", require: false
gem "sqlite3", "~> 2.1"
