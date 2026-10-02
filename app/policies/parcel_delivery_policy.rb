# frozen_string_literal: true

# Authorization policy for +ParcelDelivery+ records (front-desk side).
#
# Every action rides on manage_parcels, resolved against the parcel's
# residential property: concierge / property_admin on their assigned
# properties, organization admins everywhere. Residents never go through this
# policy — they read their unit's parcels by unit relationship instead.
class ParcelDeliveryPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_parcels) || any_accessible_property?(:manage_parcels)
  end

  def show?
    manage?
  end

  def create?
    manage?
  end

  def withdraw?
    manage?
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      resolver = authorization_resolver
      return scope.none unless resolver

      return organization_scoped if resolver.allowed?(:manage_parcels)

      property_ids = resolver.profile.property_capabilities
                             .select { |_id, caps| caps.include?(Authorization::Capabilities::MANAGE_PARCELS) }
                             .keys
      return scope.none if property_ids.empty?

      organization_scoped.where(residential_property_id: property_ids)
    end
  end

  private

  def manage?
    same_organization? && allowed?(:manage_parcels)
  end
end
