# frozen_string_literal: true

class PropertySectionPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def new?
    admin?
  end

  def create?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
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
