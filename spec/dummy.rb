# frozen_string_literal: true

# The smallest Rails app the hooks can be mounted in: an in-memory database,
# two models, a factory with a trait, and a few named routes for /__qa/pages.
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "factory_bot"
require "talooner_qa"

ENV["DATABASE_URL"] = "sqlite3::memory:"

class Dummy < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "talooner-qa-rails-test-#{'x' * 40}"
  config.hosts.clear
  config.action_dispatch.show_exceptions = :none
  config.filter_parameters += [:email]
end

Dummy.initialize!

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :orders do |t|
    t.string :number
    t.string :status
    t.decimal :total, precision: 8, scale: 2
    t.string :api_token
    t.timestamps
  end
  create_table :users do |t|
    t.string :email
    t.string :inventory_role
  end
end

class Order < ActiveRecord::Base; end
class User < ActiveRecord::Base; end

class OrdersController < ActionController::Base
  def show = head(:ok)
end

FactoryBot.define do
  factory :order do
    number { "A-7" }
    status { "open" }
    total { 19.5 }
    api_token { "secret-token-value" }

    trait :paid do
      status { "paid" }
    end
  end
end

Rails.application.routes.draw do
  mount TaloonerQa::Engine, at: "/__qa"
  get "/orders/:id", to: "orders#show", as: :order
  get "/orders", to: "orders#show", as: :orders
  post "/orders", to: "orders#show", as: :create_order
  get "/admin/reports", to: "orders#show", as: :admin_reports
  get "/rails/health", to: "orders#show", as: :rails_health
end
