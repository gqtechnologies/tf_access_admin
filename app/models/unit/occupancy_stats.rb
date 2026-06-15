# frozen_string_literal: true

class Unit::OccupancyStats
  def self.for(unit, at: Time.zone.now)
    active_scope = unit.unit_occupancies.where(status: OccupancyStatuses::ACTIVE)
    historical_scope = unit.unit_occupancies.where.not(status: OccupancyStatuses::ACTIVE)
    authorizers = UnitOccupancy.active_authorizers_for(unit, at: at)

    {
      active_occupants_count: active_scope.count,
      active_authorizers_count: authorizers.count,
      historical_occupants_count: historical_scope.count,
      total_occupants_count: unit.unit_occupancies.count
    }
  end
end
