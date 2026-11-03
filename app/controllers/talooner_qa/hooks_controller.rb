# frozen_string_literal: true

module TaloonerQa
  # The /__qa/* hooks (talooner-qa docs/hooks.md). ActionController::Base, not
  # API: login has to set the app's session cookie.
  class HooksController < ActionController::Base
    # The token is the authentication; there is no form to forge.
    skip_forgery_protection
    before_action :authenticate!

    rescue_from Seeds::Unknown, ArgumentError do |e|
      render json: { error: e.message }, status: 422
    end

    def roles
      return not_configured("roles") unless qa.roles

      render json: qa.roles.call
    end

    def pages
      render json: Pages.call(Rails.application.routes, qa.page_excludes)
    end

    def seeds
      return not_configured("seeds") if qa.named_seeds.empty? && qa.seed_sources.empty?

      render json: { seeds: Seeds.names(qa) }
    end

    def login
      return not_configured("login") unless qa.user_for

      roles = params.permit!.to_h.except("controller", "action", "hook").transform_values(&:to_s)
      raise ArgumentError, "login needs at least one {area: role}; a guest does not log in" if roles.empty?

      user = qa.user_for.call(roles)
      raise ArgumentError, "user_for returned no user for #{roles.inspect}" unless user

      sign_in_user(user)
      head :no_content
    end

    def seed
      name = params.require(:name).to_s
      record = Seeds.create(qa, name)
      render json: Seeds.attributes(record, Rails.application.config.filter_parameters)
    end

    def reset
      return not_configured("reset") unless qa.reset

      qa.reset.call
      head :no_content
    end

    def flag
      name = params.require(:name).to_s
      on = ActiveModel::Type::Boolean.new.cast(params.require(:on))
      if qa.flag
        qa.flag.call(name, on)
      elsif defined?(::Flipper)
        on ? ::Flipper.enable(name) : ::Flipper.disable(name)
      else
        return not_configured("flag")
      end
      head :no_content
    end

    def check
      name = params.require(:name).to_s
      block = qa.checks[name]
      raise ArgumentError, "no check named #{name.inspect}" unless block

      result = block.call(params.except(:controller, :action, :name).permit!.to_h.with_indifferent_access)
      # An explicit answer only: a record or nil from a sloppy block must not
      # read as a failed check, nor as a passed one.
      raise ArgumentError, "check #{name.inspect} returned #{result.inspect}, want true or false" unless [true, false].include?(result)

      render json: { ok: result }
    end

    private

      # Not `config`: that is the controller's own (logger, asset host, …).
      def qa = TaloonerQa.configuration

      # 401 for a wrong token; 404 for everything when the hooks are disabled,
      # so a mounted-by-mistake engine answers like nothing is there.
      def authenticate!
        return head(:not_found) unless TaloonerQa.enabled?

        given = request.authorization.to_s.delete_prefix("Bearer ")
        head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(given, TaloonerQa.token)
      end

      def sign_in_user(user)
        if qa.sign_in
          qa.sign_in.call(self, user)
        elsif respond_to?(:sign_in, true)
          sign_in(user)
        else
          raise ArgumentError, "no sign_in configured and Devise is not loaded: " \
                               "set TaloonerQa.configure { it.sign_in { |controller, user| ... } }"
        end
      end

      def not_configured(hook)
        render json: { error: "#{hook} is not configured" }, status: :not_found
      end
  end
end
