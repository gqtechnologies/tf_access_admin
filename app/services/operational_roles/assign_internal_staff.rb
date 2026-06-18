# frozen_string_literal: true

module OperationalRoles
  # Assigns an internal staff operational role (+cleaning_staff+ or +internal_staff+)
  # to a person on a property.
  #
  # Accepts an explicit +staff_type+ (one of +StaffTypes::CLEANING+,
  # +StaffTypes::MAINTENANCE+, or +StaffTypes::OTHER+) scoped to
  # +residential_property+. Maps to +cleaning_staff+ or +internal_staff+
  # via +Authorization::StaffRoleMapper+. No administrative or
  # access-control capabilities are granted by default.
  #
  # == Additional input
  #   staff_type: String — one of the non-manager, non-concierge StaffTypes values
  #
  # Implemented in section 8 of the operational-roles-and-permissions OpenSpec.
  class AssignInternalStaff < BaseAssignment
    # @param staff_type [String] StaffTypes constant value
    def initialize(actor:, person:, organization:, residential_property:, staff_type:)
      super(actor: actor, person: person, organization: organization, residential_property: residential_property)
      @staff_type = staff_type
    end

    # @return [Hash] { success: Boolean, assignment: StaffAssignment|nil, errors: Array<String> }
    def call
      raise NotImplementedError, "#{self.class}#call — implement in OperationalRoles section 8"
    end

    private

    attr_reader :staff_type
  end
end
