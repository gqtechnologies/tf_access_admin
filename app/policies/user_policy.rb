# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
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
    admin? && same_organization?
  end

  def update?
    admin? && same_organization?
  end

  def destroy?
    admin? && same_organization?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?
      if user.tenant_admin? || user.super_admin?
        scope.where(organization_id: user.organization_id)
      else
        scope.none
      end
    end
  end
end
