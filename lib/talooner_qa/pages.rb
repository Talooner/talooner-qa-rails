# frozen_string_literal: true

module TaloonerQa
  # Pages come from the router: every named GET route is a page, its name the
  # one the decision model answers about and its path with ":id" left for the
  # seeded data to fill.
  module Pages
    def self.call(routes, excludes)
      routes.routes.each_with_object({}) do |route, pages|
        next if route.name.blank? || !route.verb.to_s.match?(/\bGET\b/)

        path = route.path.spec.to_s.sub("(.:format)", "")
        next if excludes.any? { |pattern| path.match?(pattern) }

        pages[route.name] ||= path
      end
    end
  end
end
