# frozen_string_literal: true

module TaloonerQa
  # Seed names are opaque to talooner-qa: a block's @data:<name> must be one of
  # the names listed here, and seed(name) makes it. Named seeds win, then each
  # source in the order it was configured.
  module Seeds
    class Unknown < Error; end

    # Never returned from a seed, whatever the app's own filter says.
    ALWAYS_FILTERED = %i[passw secret token _key crypt salt digest otp].freeze

    class Source
      def initialize(names:, seed:)
        @names = names
        @seed = seed
      end

      def list = Array(@names.call).map(&:to_s)

      def create(name) = @seed.call(name)
    end

    # Every factory, and every trait as "factory:trait". One trait per name:
    # listing every combination would explode, and a combination worth testing
    # is worth a trait of its own.
    class FactoryBot
      def initialize(attributes: nil)
        @attributes = attributes
      end

      def list
        load_definitions
        ::FactoryBot.factories.flat_map do |factory|
          [factory.name.to_s] + factory.definition.defined_traits.map { "#{factory.name}:#{it.name}" }
        end
      end

      def create(name)
        factory, trait = name.split(":", 2)
        extra = @attributes&.call(factory.to_sym) || {}
        ::FactoryBot.create(factory.to_sym, *[trait&.to_sym].compact, **extra)
      end

      private

        # factory_bot_rails loads them at boot; plain factory_bot does not.
        def load_definitions
          ::FactoryBot.find_definitions if ::FactoryBot.factories.none?
        end
    end

    def self.names(config)
      (config.named_seeds.keys + config.seed_sources.flat_map(&:list)).uniq
    end

    def self.create(config, name)
      return config.named_seeds.fetch(name).call if config.named_seeds.key?(name)

      source = config.seed_sources.find { it.list.include?(name) }
      raise Unknown, "no seed named #{name.inspect}; GET /__qa/seeds lists them" unless source

      source.create(name)
    end

    # The record's scalar attributes, for filling a page's :id and the like.
    # Anything the app filters from its logs, and every secret-looking key, is
    # left out rather than masked.
    def self.attributes(record, filter_parameters = [])
      out = scalars(filtered(hash_of(record), filter_parameters))
      out["param"] = record.to_param if record.is_a?(ActiveRecord::Base) && record.to_param
      out
    end

    def self.hash_of(record)
      hash = record.is_a?(Hash) ? record : record.try(:attributes)
      raise Error, "a seed must return a record or a hash, not #{record.class}" unless hash

      hash.transform_keys(&:to_s)
    end
    private_class_method :hash_of

    def self.filtered(hash, filter_parameters)
      filter = ActiveSupport::ParameterFilter.new(ALWAYS_FILTERED + filter_parameters, mask: FILTERED)
      filter.filter(hash).reject { |_key, value| value.equal?(FILTERED) }
    end
    private_class_method :filtered

    def self.scalars(hash)
      hash.filter_map do |key, value|
        scalar = scalar(value)
        [key, scalar] unless scalar.nil?
      end.to_h
    end
    private_class_method :scalars

    FILTERED = Object.new.freeze
    private_constant :FILTERED

    def self.scalar(value)
      case value
      when String, Integer, Float, true, false then value
      when BigDecimal then value.to_s("F")
      when Time, Date, DateTime, ActiveSupport::TimeWithZone then value.iso8601
      end
    end
    private_class_method :scalar
  end
end
