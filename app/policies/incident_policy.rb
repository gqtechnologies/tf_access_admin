# frozen_string_literal: true

# Incidents are reported by residents (through their unit relationship, checked
# in Incidents::Report) and by front-desk staff holding report_incidents on the
# property; they are managed — assigned, moved and closed — by actors holding
# manage_incidents on the property.
class IncidentPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_incidents) || any_accessible_property?(:manage_incidents)
  end

  def report_as_staff?
    same_organization? && (allowed?(:report_incidents) || allowed?(:manage_incidents))
  end

  def manage?
    same_organization? && allowed?(:manage_incidents)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      resolver = authorization_resolver
      return scope.none unless resolver

      return organization_scoped if resolver.allowed?(:manage_incidents)

      property_ids = resolver.profile.property_capabilities
                             .select { |_id, caps| caps.include?(Authorization::Capabilities::MANAGE_INCIDENTS) }
                             .keys
      return scope.none if property_ids.empty?

      organization_scoped.where(residential_property_id: property_ids)
    end
  end
end
