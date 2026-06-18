# frozen_string_literal: true

class UnitOccupancyPolicy < ApplicationPolicy
  def index?
    allowed?(:manage_occupancies) || any_accessible_property?(:manage_occupancies)
  end

  def show?
    same_organization? && unit_and_person_same_organization? && allowed?(:manage_occupancies)
  end

  def create?
    same_organization? && unit_and_person_same_organization? && allowed?(:manage_occupancies)
  end

  def update?
    same_organization? && unit_and_person_same_organization? && allowed?(:manage_occupancies)
  end

  def destroy?
    same_organization? && unit_and_person_same_organization? && allowed?(:manage_occupancies)
  end

  class Scope < ApplicationPolicy::Scope
    include PolicyScopeAuthorization

    def resolve
      return scope.none unless user.present?

      ids = accessible_property_ids
      return scope.none if ids.empty?

      organization_scoped.joins(:unit).where(units: { residential_property_id: ids })
    end
  end

  private

  def unit_and_person_same_organization?
    return false unless record.respond_to?(:unit) && record.respond_to?(:person)
    return false if record.unit.blank? || record.person.blank?

    org_id = current_organization&.id
    return false unless org_id

    record.unit.organization_id == org_id &&
      record.person.organization_id == org_id
  end
end
