# frozen_string_literal: true

# The shift log is read by whoever manages a property's staff assignments.
# Workers open and close their own shifts through the concierge API.
class StaffShiftPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_staff_assignments) || any_accessible_property?(:manage_staff_assignments)
  end
end
