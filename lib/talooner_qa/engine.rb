# frozen_string_literal: true

module TaloonerQa
  # Mount it only when enabled:
  #
  #   mount TaloonerQa::Engine, at: "/__qa" if TaloonerQa.enabled?
  class Engine < ::Rails::Engine
    isolate_namespace TaloonerQa
  end
end
