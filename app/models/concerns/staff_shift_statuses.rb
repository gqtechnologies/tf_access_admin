# frozen_string_literal: true

# Allowed +staff_shifts.status+ values (string-backed; supports +in_progress+ for active shifts).
module StaffShiftStatuses
  SCHEDULED   = "scheduled"
  IN_PROGRESS = "in_progress"
  COMPLETED   = "completed"
  CANCELLED   = "cancelled"
  MISSED      = "missed"

  ALL = [ SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED, MISSED ].freeze
end
