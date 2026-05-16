# frozen_string_literal: true

# Shared priority strings for +incidents.priority+ and +announcements.priority+.
module Priorities
  LOW    = "low"
  NORMAL = "normal"
  HIGH   = "high"
  URGENT = "urgent"

  ALL = [ LOW, NORMAL, HIGH, URGENT ].freeze
end
