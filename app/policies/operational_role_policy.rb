# frozen_string_literal: true

# Policy for managing operational roles and staff assignments.
# All actions require :manage_staff_assignments capability — held org-wide
# (tenant_admin) or on at least one accessible property (property_admin).
class OperationalRolePolicy < ApplicationPolicy
  def index?
    allowed?(:manage_staff_assignments) || any_accessible_property?(:manage_staff_assignments)
  end

  def show?
    index?
  end

  def create?
    index?
  end

  # record is a StaffAssignment — check capability scoped to its property.
  def destroy?
    return allowed?(:manage_staff_assignments) unless record.respond_to?(:residential_property_id)

    property_allowed?(:manage_staff_assignments, property_id: record.residential_property_id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      org = ActsAsTenant.current_tenant
      base = Authorization::Resolver.new(user: user, organization: org)
      if base.profile.organization_wide?
        scope.all
      else
        scope.where(residential_property_id: base.accessible_property_ids)
      end
    end
  end
end
