# frozen_string_literal: true

class OrganizationPolicy < ApplicationPolicy
  def index?
    admin?
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
