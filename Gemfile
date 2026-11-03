# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "factory_bot", "~> 6.5"
# CI sets RAILS_VERSION to test each supported Rails.
rails = ENV.fetch("RAILS_VERSION", "~> 8.1")
gem "rails", rails

# ActiveSupport before 8.1 passes json's removed quirks_mode option; an app on
# those Rails already has json < 3 locked, so the matrix does the same.
gem "json", "< 3" unless rails.include?("8.1")
gem "rspec-rails", "~> 7.0"
gem "rubocop", "~> 1.75", require: false
gem "sqlite3", "~> 2.1"
