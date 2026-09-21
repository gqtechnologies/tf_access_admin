# frozen_string_literal: true

module Api
  # Resolves the role exposed by the mobile API for a user within an organization.
  # Administrative organizational roles win, then an active concierge staff
  # assignment; any other member is a resident (owner/occupant).
  module RoleResolver
    RESIDENT = "resident"
    CONCIERGE = "concierge"

    module_function

    def call(user, organization)
      return AvailableRoles::SUPER_ADMIN if user.super_admin?

      tenant_role = ActsAsTenant.with_tenant(organization) { user.tenant_role }
      # `visitor` must not outrank an active concierge assignment: a concierge
      # may have been invited as a visitor before being hired.
      return tenant_role if tenant_role.in?(AvailableRoles::TENANT_ROLE_PRIORITY - [ AvailableRoles::VISITOR ])
      return CONCIERGE if concierge?(user, organization)
      return tenant_role if tenant_role == AvailableRoles::VISITOR

      RESIDENT
    end

    # Concierge is not an organizational role: it is an active StaffAssignment.
    def concierge?(user, organization)
      ActsAsTenant.with_tenant(organization) do
        person = user.person_for(organization)
        next false if person.blank?

        StaffAssignment.currently_active
                       .where(person: person, staff_type: StaffTypes::CONCIERGE)
                       .exists?
      end
    end
  end
end
