# frozen_string_literal: true

require "talooner_qa/version"

# The test-only /__qa/* API talooner-qa drives (talooner-qa docs/hooks.md).
#
# /__qa/login signs in as any role, so these hooks are a backdoor wherever they
# answer without the token: mount them only when enabled?, and every request
# is checked against TALOONER_QA_HOOK_TOKEN again.
module TaloonerQa
  TOKEN_VARIABLE = "TALOONER_QA_HOOK_TOKEN"
  ALLOW_PRODUCTION_VARIABLE = "TALOONER_QA_ALLOW_PRODUCTION"

  class Error < StandardError; end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def token
      ENV.fetch(TOKEN_VARIABLE, "").strip.presence
    end

    # True only with a token, and never in production unless asked for by name.
    def enabled?
      return false unless token
      return true unless defined?(Rails) && Rails.env.production?

      ENV[ALLOW_PRODUCTION_VARIABLE] == "1"
    end
  end
end

require "talooner_qa/configuration"
require "talooner_qa/pages"
require "talooner_qa/seeds"
require "talooner_qa/engine" if defined?(Rails::Engine)
