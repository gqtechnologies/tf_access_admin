# frozen_string_literal: true

require "test_helper"

class Unit::OccupancyStatsTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Occupancy Stats Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      identifier: "OCC-STATS-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    @person = Person.create!(
      organization: @organization,
      display_name: "Stats Occupant",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    @other_person = Person.create!(
      organization: @organization,
      display_name: "Stats Other Occupant",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "for returns active historical authorizer and total counts" do
    today = Time.zone.parse("2026-06-14 12:00")

    UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: @person,
      occupancy_type: OccupancyTypes::TENANT,
      can_authorize_visits: true,
      starts_at: today.beginning_of_day,
      status: OccupancyStatuses::ACTIVE
    )
    UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: @other_person,
      occupancy_type: OccupancyTypes::FAMILY_MEMBER,
      can_authorize_visits: false,
      starts_at: today.beginning_of_day - 30.days,
      status: OccupancyStatuses::INACTIVE
    )

    stats = Unit::OccupancyStats.for(@unit, at: today)

    assert_equal 1, stats[:active_occupants_count]
    assert_equal 1, stats[:active_authorizers_count]
    assert_equal 1, stats[:historical_occupants_count]
    assert_equal 2, stats[:total_occupants_count]
  end

  test "for excludes soft-deleted occupancies from totals" do
    occupancy = UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: @person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: OccupancyStatuses::ACTIVE
    )
    occupancy.destroy

    stats = Unit::OccupancyStats.for(@unit)

    assert_equal 0, stats[:active_occupants_count]
    assert_equal 0, stats[:total_occupants_count]
  end
end
