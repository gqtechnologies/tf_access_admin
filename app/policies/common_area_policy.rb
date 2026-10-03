# frozen_string_literal: true

# Configuration of a property's common areas and the decisions on their
# reservations, both on manage_common_areas resolved against the property.
# Residents never go through this policy: they reserve through the private API,
# which checks their unit relationship and the occupancy's
# can_reserve_common_areas flag.
class CommonAreaPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_common_areas) || any_accessible_property?(:manage_common_areas)
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  # Approve / reject / cancel a reservation of this area.
  def decide?
    manage?
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      resolver = authorization_resolver
      return scope.none unless resolver

      return organization_scoped if resolver.allowed?(:manage_common_areas)

      property_ids = resolver.profile.property_capabilities
                             .select { |_id, caps| caps.include?(Authorization::Capabilities::MANAGE_COMMON_AREAS) }
                             .keys
      return scope.none if property_ids.empty?

      organization_scoped.where(residential_property_id: property_ids)
    end
  end

  private

  def manage?
    same_organization? && allowed?(:manage_common_areas)
  end
end
