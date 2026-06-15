# frozen_string_literal: true

module UnitOccupancies
  class ActiveElsewhereForPerson
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(person:, exclude_unit:, at: Time.zone.now)
      @person = person
      @exclude_unit = exclude_unit
      @at = at
    end

    def call
      active_elsewhere_scope.map { |occupancy| serialize(occupancy) }
    end

    private

    def active_elsewhere_scope
      zone = ActiveSupport::TimeZone[Mutation.time_zone_for(@exclude_unit)] || Time.zone
      day_start = @at.in_time_zone(zone).beginning_of_day
      day_end = @at.in_time_zone(zone).end_of_day

      UnitOccupancy
        .where(
          person_id: @person.id,
          organization_id: @person.organization_id,
          status: OccupancyStatuses::ACTIVE
        )
        .where.not(unit_id: @exclude_unit.id)
        .where("unit_occupancies.starts_at <= ?", day_end)
        .where("unit_occupancies.ends_at IS NULL OR unit_occupancies.ends_at >= ?", day_start)
        .includes(unit: [ :property_section, :residential_property ])
        .order("unit_occupancies.starts_at DESC")
    end

    def serialize(occupancy)
      unit = occupancy.unit
      property = unit.residential_property
      section = unit.property_section

      {
        occupancy_id: occupancy.id,
        occupancy_type: occupancy.occupancy_type,
        occupancy_type_label: occupancy_type_label(occupancy.occupancy_type),
        starts_at: occupancy.starts_at,
        ends_at: occupancy.ends_at,
        unit: {
          id: unit.id,
          identifier: unit.identifier,
          display_name: unit.display_name
        },
        property: {
          id: property.id,
          name: property.name
        },
        property_section: section.present? ? { id: section.id, name: section.name } : nil
      }
    end

    def occupancy_type_label(occupancy_type)
      I18n.t(
        "frontend.admin.unit_occupancies.occupancy_types.#{occupancy_type}",
        default: occupancy_type.to_s.humanize
      )
    end
  end
end
