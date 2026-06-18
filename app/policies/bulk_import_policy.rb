# frozen_string_literal: true

class BulkImportPolicy < ApplicationPolicy
  def create?
    allowed?(:manage_properties) || any_accessible_property?(:manage_units)
  end

  def update?
    bulk_import_allowed?
  end

  def validate?
    update?
  end

  def rows?
    update?
  end

  def confirm?
    update?
  end

  def status?
    update?
  end

  def report?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      org = current_organization
      return scope.none unless org

      base = organization_scoped
      resolver = authorization_resolver
      return scope.none unless resolver

      return base if resolver.allowed?(:manage_properties)

      property_ids = accessible_property_ids
      return scope.none if property_ids.empty?

      base.where(residential_property_id: property_ids)
    end
  end

  private

  def bulk_import_allowed?
    return false unless same_organization?

    if record.residential_property_id.blank?
      return allowed?(:manage_properties)
    end

    property = record.residential_property
    return false unless property

    property_accessible?(property) && allowed?(:manage_units)
  end
end
