# frozen_string_literal: true

# Authorization policy for +Visit+ records.
#
# Capability-to-action contract (implementation of OpenSpec 4.1–4.3):
#
#   index?      → view_visits (org/property-wide) or view_authorized_visits (concierge, property-scoped)
#   show?       → view_visits or view_authorized_visits, scoped to the visit's property
#   create?     → create_visits, scoped to the visit's unit (resident/owner context)
#   authorize?  → authorize_visits, scoped to the visit's unit
#   check_in?   → register_visit_entry, scoped to the visit's residential_property
#   check_out?  → register_visit_exit, scoped to the visit's residential_property
#
# Scope rules:
#   - organization_admin/tenant_admin → all visits in the organization
#   - property_admin                  → visits for accessible (assigned) properties
#   - concierge                       → visits for assigned properties (minimal access)
#   - resident/owner                  → visits linked to their active units only
#   - client without assignment       → no visits
#   - cross-organization              → always denied
#
class VisitPolicy < ApplicationPolicy
  # List: tenant_admin/property_admin (manage_visits), concierge (view_authorized_visits)
  def index?
    allowed?(:view_visits) || allowed?(:manage_visits) ||
      any_accessible_property?(:view_visits) || any_accessible_property?(:view_authorized_visits)
  end

  # Show: requires view_visits or view_authorized_visits scoped to the visit's property
  def show?
    return false unless same_organization?

    allowed?(:view_visits) || allowed?(:manage_visits) ||
      allowed?(:view_authorized_visits) || allowed?(:view_minimal_access_control_data)
  end

  # Create: residents and owners via create_visits, property_admin/tenant_admin via manage_visits
  def create?
    return false unless same_organization?

    allowed?(:create_visits) || allowed?(:manage_visits)
  end

  def new?
    create?
  end

  # Update: property_admin/tenant_admin
  def update?
    same_organization? && allowed?(:manage_visits)
  end

  def edit?
    update?
  end

  # Destroy: only org-wide managers
  def destroy?
    same_organization? && allowed?(:manage_visits)
  end

  # Authorize: resident or owner with authorize_visits on the visit's unit
  def authorize?
    return false unless same_organization?

    allowed?(:authorize_visits)
  end

  # Check-in (register entry): concierge or property_admin on the visit's property
  def check_in?
    return false unless same_organization?

    allowed?(:register_visit_entry)
  end

  # Check-out (register exit): concierge or property_admin on the visit's property
  def check_out?
    return false unless same_organization?

    allowed?(:register_visit_exit)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      org = current_organization
      return scope.none unless org

      resolver = authorization_resolver
      return scope.none unless resolver

      # org-wide roles see all visits in the organization
      return organization_scoped if resolver.allowed?(:view_visits) || resolver.allowed?(:manage_visits)

      # property-scoped roles (concierge, property_admin) see visits on accessible properties
      property_ids = accessible_property_ids

      # unit-scoped roles (owner/resident) see visits on their active units
      unit_ids = resolver.profile.unit_capabilities
                         .select { |_id, caps| caps.include?(:create_visits) || caps.include?(:authorize_visits) }
                         .keys

      return scope.none if property_ids.empty? && unit_ids.empty?

      base = organization_scoped
      relation = base.none
      relation = relation.or(base.where(residential_property_id: property_ids)) if property_ids.any?
      relation = relation.or(base.where(unit_id: unit_ids)) if unit_ids.any?

      relation
    end
  end
end
