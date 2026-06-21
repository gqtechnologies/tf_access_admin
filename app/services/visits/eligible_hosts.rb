# frozen_string_literal: true

module Visits
  class EligibleHosts
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, at: Time.zone.now)
      @unit = unit
      @at = at
    end

    def call
      person_ids = ownership_person_ids + occupancy_person_ids
      return Person.none if person_ids.empty?

      Person.where(organization_id: @unit.organization_id, id: person_ids.uniq)
            .order(:display_name)
    end

    private

    def ownership_person_ids
      UnitOwnership
        .where(
          unit_id: @unit.id,
          organization_id: @unit.organization_id,
          status: UnitOwnership::STATUS_ACTIVE
        )
        .where("starts_at <= ?", @at.to_date)
        .where("ends_at IS NULL OR ends_at >= ?", @at.to_date)
        .pluck(:person_id)
    end

    def occupancy_person_ids
      day_start = @at.in_time_zone.beginning_of_day
      day_end = @at.in_time_zone.end_of_day

      UnitOccupancy
        .where(
          unit_id: @unit.id,
          organization_id: @unit.organization_id,
          status: OccupancyStatuses::ACTIVE
        )
        .where("starts_at <= ?", day_end)
        .where("ends_at IS NULL OR ends_at >= ?", day_start)
        .pluck(:person_id)
    end
  end
end
