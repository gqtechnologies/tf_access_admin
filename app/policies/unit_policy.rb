# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  def show?
    admin? && same_organization?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      tenant = ActsAsTenant.current_tenant
      return scope.none unless tenant

      if user.super_admin? || user.tenant_admin?(tenant)
        scope.where(organization_id: tenant.id)
      else
        scope.none
      end
    end
  end
end
