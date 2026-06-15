# frozen_string_literal: true

# Allowed +unit_occupancies.occupancy_type+ values (string-backed).
module OccupancyTypes
  OWNER_RESIDENT       = "owner_resident"
  TENANT               = "tenant"
  FAMILY_MEMBER        = "family_member"
  TEMPORARY_RESIDENT   = "temporary_resident"
  AUTHORIZED_MANAGER   = "authorized_manager"
  OTHER                = "other"

  ALL = [
    OWNER_RESIDENT,
    TENANT,
    FAMILY_MEMBER,
    TEMPORARY_RESIDENT,
    AUTHORIZED_MANAGER,
    OTHER
  ].freeze

  LEGACY_TYPE_MAP = {
    "owner" => OWNER_RESIDENT,
    "family" => FAMILY_MEMBER
  }.freeze
end
