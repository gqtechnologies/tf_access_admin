# frozen_string_literal: true

class IconPolicy < ApplicationPolicy
  def index?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?
      return scope.all if user.tenant_admin? || user.super_admin?

      scope.none
    end
  end
end
