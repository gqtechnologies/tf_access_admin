# frozen_string_literal: true

module OperationalRoles
  # Revokes (deactivates) an active +StaffAssignment+.
  #
  # == Input contract
  #
  #   actor:      User — operator performing the revocation (for audit)
  #   assignment: StaffAssignment — the active assignment to revoke
  #
  # == Output contract
  #
  # +call+ returns a plain Hash:
  #
  #   {
  #     success:    Boolean,
  #     assignment: StaffAssignment,   # updated record with status inactive
  #     errors:     Array<String>
  #   }
  #
  # On success the +StaffAssignment+ status is set to +STATUS_INACTIVE+ and
  # +ends_at+ is set to the current date if not already set. An audit record
  # is produced via +audited+.
  #
  # Implemented in section 8 of the operational-roles-and-permissions OpenSpec.
  class RevokeAssignment
    # @param actor [User]
    # @param assignment [StaffAssignment]
    def initialize(actor:, assignment:)
      @actor = actor
      @assignment = assignment
    end

    # @return [Hash] { success: Boolean, assignment: StaffAssignment, errors: Array<String> }
    def call
      raise NotImplementedError, "#{self.class}#call — implement in OperationalRoles section 8"
    end

    private

    attr_reader :actor, :assignment
  end
end
