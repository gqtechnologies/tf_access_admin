# frozen_string_literal: true

# The administration's side of authorized people: approving, rejecting and
# revoking ride on manage_occupancies (the same people who manage a unit's
# residents). Residents propose through the private API instead.
class AuthorizedResidentPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_occupancies) || any_accessible_property?(:manage_occupancies)
  end

  # Approve / reject / revoke, resolved against the unit's property.
  def decide?
    same_organization? && allowed?(:manage_occupancies)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      resolver = authorization_resolver
      return scope.none unless resolver

      return organization_scoped if resolver.allowed?(:manage_occupancies)

      property_ids = resolver.profile.property_capabilities
                             .select { |_id, caps| caps.include?(Authorization::Capabilities::MANAGE_OCCUPANCIES) }
                             .keys
      return scope.none if property_ids.empty?

      organization_scoped.joins(:unit).where(units: { residential_property_id: property_ids })
    end
  end
end
