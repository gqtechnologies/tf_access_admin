# frozen_string_literal: true

# Allowed +people.status+ values (string-backed).
module PersonStatuses
  ACTIVE = "active"
  INACTIVE = "inactive"

  ALL = [
    ACTIVE,
    INACTIVE
  ].freeze
end
