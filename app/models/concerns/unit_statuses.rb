# frozen_string_literal: true

# Allowed +units.status+ values (string-backed).
module UnitStatuses
  AVAILABLE = "available"
  OCCUPIED = "occupied"
  INACTIVE = "inactive"
  MAINTENANCE = "maintenance"

  ALL = [
    AVAILABLE,
    OCCUPIED,
    INACTIVE,
    MAINTENANCE
  ].freeze
end
