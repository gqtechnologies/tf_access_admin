# frozen_string_literal: true

module OperationalRoles
  # Assigns the +concierge+ operational role to a person on a property.
  #
  # Creates or activates a +StaffAssignment+ with +staff_type: StaffTypes::CONCIERGE+
  # scoped to the given +residential_property+. The assignment grants capabilities
  # from +Authorization::Capabilities::CONCIERGE+ (visit access-control) within
  # that property only. No administrative capabilities are granted.
  #
  # Requires the person to have a linked +User+ because concierge role implies
  # interactive system access.
  #
  # Implemented in section 8 of the operational-roles-and-permissions OpenSpec.
  class AssignConcierge < BaseAssignment
    # @return [Hash] { success: Boolean, assignment: StaffAssignment|nil, errors: Array<String> }
    def call
      raise NotImplementedError, "#{self.class}#call — implement in OperationalRoles section 8"
    end
  end
end
