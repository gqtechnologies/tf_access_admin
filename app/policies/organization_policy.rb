# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  def index?
    super_admin?
  end


  def new?
    super_admin?
  end

  def create?
    super_admin?
  end

  def show?
    super_admin? || (same_organization? && user.tenant_admin?(record))
  end

  def edit?
    super_admin? || (same_organization? && user.tenant_admin?(record))
  end

  def update?
    super_admin? || (same_organization? && user.tenant_admin?(record))
  end

  def destroy?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      if user.super_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
