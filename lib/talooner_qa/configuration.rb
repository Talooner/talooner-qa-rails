# frozen_string_literal: true

module TaloonerQa
  # What only the app knows. A hook whose part is not configured answers 404,
  # which talooner-qa reads as "not implemented" (roles and pages fall back to
  # files; the others fail the run).
  class Configuration
    attr_reader :checks, :named_seeds, :seed_sources, :page_excludes

    def initialize
      @checks = {}
      @named_seeds = {}
      @seed_sources = []
      @page_excludes = [%r{\A/rails/}, %r{\A/__qa}, %r{\A/assets}, %r{\A/cable}, %r{\A/up\z}]
    end

    # {area => [role, ...]}: the app's roles, including ones added at runtime.
    def roles(&block)
      block ? @roles = block : @roles
    end

    # A user with exactly these roles ({"inventory" => "admin"}) and no access
    # elsewhere; find or create it.
    def user_for(&block)
      block ? @user_for = block : @user_for
    end

    # How a user is signed in. Defaults to Devise's sign_in when it is loaded.
    def sign_in(&block)
      block ? @sign_in = block : @sign_in
    end

    # A seed by name, e.g. seed("paid_order") { Order.create!(...) }. Named
    # seeds win over every source.
    def seed(name, &block)
      @named_seeds[name.to_s] = block
    end

    # A source of many seeds: names lists them, seed creates one. This is how
    # a seed script that names its records (a "world") is exposed.
    def seeds(names:, seed:)
      @seed_sources << Seeds::Source.new(names:, seed:)
    end

    # Every FactoryBot factory as "factory" and every trait as "factory:trait".
    # attributes { |factory| {...} } adds attributes to each create, e.g. the
    # account the record belongs to.
    def seeds_from_factory_bot(attributes: nil)
      @seed_sources << Seeds::FactoryBot.new(attributes:)
    end

    def reset(&block)
      block ? @reset = block : @reset
    end

    # flag { |name, on| ... }. Defaults to Flipper when it is loaded.
    def flag(&block)
      block ? @flag = block : @flag
    end

    # check("refund recorded") { |params| Refund.exists?(order_id: params[:id]) }
    def check(name, &block)
      @checks[name.to_s] = block
    end

    # Paths matching any of these are left out of /__qa/pages.
    def exclude_pages(*patterns)
      @page_excludes.concat(patterns)
    end
  end
end
