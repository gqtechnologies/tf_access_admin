# frozen_string_literal: true

# Allowed +lease_contracts.status+ values (string-backed).
module LeaseStatuses
  DRAFT      = "draft"
  ACTIVE     = "active"
  TERMINATED = "terminated"

  ALL = [ DRAFT, ACTIVE, TERMINATED ].freeze
end
