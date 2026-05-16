# frozen_string_literal: true

# Allowed +staff_assignments.staff_type+ values (string-backed).
module StaffTypes
  CONCIERGE     = "concierge"
  SECURITY      = "security"
  CLEANING      = "cleaning"
  MANAGER       = "manager"
  MAINTENANCE   = "maintenance"
  OTHER         = "other"

  ALL = [ CONCIERGE, SECURITY, CLEANING, MANAGER, MAINTENANCE, OTHER ].freeze
end
