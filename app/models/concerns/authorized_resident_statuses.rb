# frozen_string_literal: true

# Allowed +authorized_residents.status+ values (string-backed).
module AuthorizedResidentStatuses
  PENDING  = "pending"
  ACTIVE   = "active"
  REJECTED = "rejected"
  REVOKED  = "revoked"

  ALL = [ PENDING, ACTIVE, REJECTED, REVOKED ].freeze
end
