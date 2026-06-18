# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy
  def index?
    allowed?(:view_units) || allowed?(:manage_units) ||
      any_accessible_property?(:view_units) || any_accessible_property?(:manage_units)
  end

  def show?
    return false unless same_organization?

    allowed?(:view_units) || allowed?(:manage_units) || allowed?(:view_own_unit_context)
  end

  def new?
    create?
  end

  def create?
    same_organization? && allowed?(:manage_units)
  end

  def edit?
    update?
  end

  def update?
    same_organization? && allowed?(:manage_units)
  end

  def destroy?
    same_organization? && allowed?(:manage_units)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      ids = accessible_property_ids
      unit_ids = authorization_resolver&.profile&.unit_capabilities&.keys || []
      return scope.none if ids.empty? && unit_ids.empty?

      base = organization_scoped
      relation = base.where(residential_property_id: ids)
      relation = relation.or(base.where(id: unit_ids)) if unit_ids.any?

      relation
    end
  end
end
