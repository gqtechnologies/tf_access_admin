# frozen_string_literal: true

# Allowed +residential_properties.status+ values (string-backed lifecycle).
#
# - +active+:   operational property that admits normal management.
# - +inactive+: temporarily suspended, reversible.
# - +archived+: retired property, preserved for history and consultation (terminal).
module PropertyStatuses
  ACTIVE   = "active"
  INACTIVE = "inactive"
  ARCHIVED = "archived"

  ALL = [
    ACTIVE,
    INACTIVE,
    ARCHIVED
  ].freeze
end
