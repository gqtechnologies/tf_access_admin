# frozen_string_literal: true

class Unit::OwnershipStats
  def self.for(unit)
    active_scope = unit.unit_ownerships.where(status: UnitOwnership::STATUS_ACTIVE)
    historical_scope = unit.unit_ownerships.where.not(status: UnitOwnership::STATUS_ACTIVE)

    assigned = active_scope.sum(:ownership_percentage).to_d
    assigned_f = assigned.to_f

    {
      active_owners_count: active_scope.count,
      assigned_percentage: assigned_f,
      available_percentage: [ 100.0 - assigned_f, 0.0 ].max,
      historical_owners_count: historical_scope.count,
      total_owners_count: unit.unit_ownerships.count
    }
  end
end
