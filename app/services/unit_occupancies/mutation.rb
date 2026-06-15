# frozen_string_literal: true

module UnitOccupancies
  module Mutation
    OCCUPANCY_ASSIGNMENT_KEYS = %i[occupancy_type can_authorize_visits starts_at ends_at status].freeze

    module_function

    def with_unit_lock(unit)
      result = nil
      unit.with_lock do
        result = yield
      end
      result
    end

    def occupancy_attributes(unit:, person:, occupancy_params:)
      {
        organization: unit.organization,
        unit: unit,
        person: person,
        occupancy_type: occupancy_params[:occupancy_type],
        can_authorize_visits: cast_boolean(occupancy_params[:can_authorize_visits]),
        starts_at: normalize_starts_at(occupancy_params[:starts_at], unit),
        ends_at: normalize_ends_at(occupancy_params[:ends_at], unit),
        status: occupancy_params[:status].presence || OccupancyStatuses::ACTIVE
      }
    end

    def normalize_starts_at(value, unit)
      zone = time_zone_for(unit)
      return Time.current.in_time_zone(zone).beginning_of_day.utc if value.blank?

      parse_datetime(value, zone).beginning_of_day.utc
    end

    def normalize_ends_at(value, unit)
      return nil if value.blank?

      zone = time_zone_for(unit)
      parse_datetime(value, zone).end_of_day.utc
    end

    def time_zone_for(unit)
      unit.residential_property&.timezone.presence || Time.zone.name
    end

    def parse_datetime(value, zone_name)
      zone = ActiveSupport::TimeZone[zone_name] || Time.zone

      case value
      when Date
        zone.parse(value.to_s)
      when Time, ActiveSupport::TimeWithZone, DateTime
        value.in_time_zone(zone)
      else
        zone.parse(value.to_s)
      end
    end

    def cast_boolean(value)
      return false if value.nil?

      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
