# frozen_string_literal: true

require_relative "dummy"
require "rspec/rails"

TOKEN = "qa_hook_token_0123456789"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with(:rspec) { it.syntax = :expect }

  config.around do |example|
    previous = ENV.to_h.slice(TaloonerQa::TOKEN_VARIABLE, TaloonerQa::ALLOW_PRODUCTION_VARIABLE)
    ENV[TaloonerQa::TOKEN_VARIABLE] = TOKEN
    TaloonerQa.reset_configuration!
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  ensure
    ENV.delete(TaloonerQa::TOKEN_VARIABLE)
    ENV.delete(TaloonerQa::ALLOW_PRODUCTION_VARIABLE)
    ENV.update(previous)
  end
end

module HookHelpers
  def hook(method, path, body = nil, token: TOKEN)
    headers = { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
    if body
      headers["Content-Type"] = "application/json"
      body = body.to_json
    end
    public_send(method, "/__qa/#{path}", params: body, headers:)
  end

  def json = JSON.parse(response.body)
end

RSpec.configure { it.include HookHelpers, type: :request }
