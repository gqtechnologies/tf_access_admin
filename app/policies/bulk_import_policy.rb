# frozen_string_literal: true

class BulkImportPolicy < ApplicationPolicy
  def create?
    admin?
  end

  def update?
    admin? && record.residential_property_id.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      tenant = ActsAsTenant.current_tenant
      return scope.none unless tenant

      if user.super_admin? || user.tenant_admin?(tenant)
        scope.all
      else
        scope.none
      end
    end
  end
end
