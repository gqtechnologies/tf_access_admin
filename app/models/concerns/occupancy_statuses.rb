# frozen_string_literal: true

# Allowed +unit_occupancies.status+ values (string-backed).
module OccupancyStatuses
  ACTIVE = "active"
  INACTIVE = "inactive"

  ALL = [ ACTIVE, INACTIVE ].freeze
end
