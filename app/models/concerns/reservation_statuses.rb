# frozen_string_literal: true

# Allowed +common_area_reservations.status+ values (string-backed).
module ReservationStatuses
  PENDING   = "pending"
  APPROVED  = "approved"
  REJECTED  = "rejected"
  CANCELLED = "cancelled"

  ALL = [ PENDING, APPROVED, REJECTED, CANCELLED ].freeze

  # The statuses that hold the slot — the database's no-overlap constraint
  # (common_area_reservations_no_overlap) applies to exactly these.
  ACTIVE = [ PENDING, APPROVED ].freeze
end
