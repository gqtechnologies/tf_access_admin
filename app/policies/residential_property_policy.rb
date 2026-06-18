# frozen_string_literal: true

class ResidentialPropertyPolicy < ApplicationPolicy
  def index?
    resolver.accessible_property_ids.any?
  end

  def show?
    same_organization? && property_accessible?(record)
  end

  def new?
    allowed?(:manage_properties)
  end

  def create?
    allowed?(:manage_properties)
  end

  def edit?
    update?
  end

  def update?
    same_organization? && allowed?(:manage_property)
  end

  def destroy?
    allowed?(:manage_properties)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      ids = accessible_property_ids
      return scope.none if ids.empty?

      organization_scoped.where(id: ids)
    end
  end
end
