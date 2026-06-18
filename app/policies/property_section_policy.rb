# frozen_string_literal: true

class PropertySectionPolicy < ApplicationPolicy
  def index?
    any_accessible_property?(:manage_sections) || allowed?(:manage_sections)
  end

  def show?
    same_organization? && allowed?(:manage_sections)
  end

  def new?
    create?
  end

  def create?
    allowed?(:manage_sections)
  end

  def edit?
    update?
  end

  def update?
    same_organization? && allowed?(:manage_sections)
  end

  def destroy?
    same_organization? && allowed?(:manage_sections)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      scoped_to_accessible_properties
    end
  end
end
