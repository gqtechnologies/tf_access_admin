# frozen_string_literal: true

# Allowed +unit_occupancies.occupancy_type+ values (string-backed).
module OccupancyTypes
  OWNER   = "owner"
  TENANT  = "tenant"
  FAMILY  = "family"
  OTHER   = "other"

  ALL = [ OWNER, TENANT, FAMILY, OTHER ].freeze
end
