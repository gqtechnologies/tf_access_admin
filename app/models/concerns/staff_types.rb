# frozen_string_literal: true

# Allowed +staff_assignments.staff_type+ values (string-backed).
#
# Persisted on +StaffAssignment+ as the operational staff role per property.
# Maps to contextual staff badges in +People::ContextualRoles+ when staff flows
# are integrated (+concierge+, +property_admin+, +cleaning_staff+).
module StaffTypes
  CONCIERGE     = "concierge"
  SECURITY      = "security"
  CLEANING      = "cleaning"
  MANAGER       = "manager"
  MAINTENANCE   = "maintenance"
  OTHER         = "other"

  ALL = [ CONCIERGE, SECURITY, CLEANING, MANAGER, MAINTENANCE, OTHER ].freeze
end
