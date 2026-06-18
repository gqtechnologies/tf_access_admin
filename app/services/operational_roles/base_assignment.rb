# frozen_string_literal: true

module OperationalRoles
  # Abstract base class for operational role assignment services.
  #
  # == Input contract
  #
  #   actor:                 User — the operator performing the assignment (for audit)
  #   person:                Person — the target person receiving the role
  #   organization:          Organization — current tenant; must match person.organization
  #   residential_property:  ResidentialProperty — scope of the assignment
  #
  # == Output contract
  #
  # +call+ returns a plain Hash:
  #
  #   {
  #     success:    Boolean,
  #     assignment: StaffAssignment | nil,
  #     errors:     Array<String>
  #   }
  #
  # == Rules
  #
  # - The assignment is always scoped to one +residential_property+; no global roles are created.
  # - If the person has no linked +User+ and the role requires system access, the service
  #   returns success: false with an appropriate error.
  # - On success an audit record is produced via +audited+.
  # - Implementations must validate that +person+ and +residential_property+ belong to +organization+.
  class BaseAssignment
    # @param actor [User]
    # @param person [Person]
    # @param organization [Organization]
    # @param residential_property [ResidentialProperty]
    def initialize(actor:, person:, organization:, residential_property:)
      @actor = actor
      @person = person
      @organization = organization
      @residential_property = residential_property
    end

    # @return [Hash] { success: Boolean, assignment: StaffAssignment|nil, errors: Array<String> }
    def call
      raise NotImplementedError, "#{self.class}#call must be implemented in section 8"
    end

    private

    attr_reader :actor, :person, :organization, :residential_property
  end
end
