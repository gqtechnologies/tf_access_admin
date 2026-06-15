# frozen_string_literal: true

require "test_helper"

class Unit::ChangeHistoryTest < ActiveSupport::TestCase
  test "formats unit status update audit entry" do
    organization = organizations(:one)
    user = users(:one)
    user.update_columns(name: "Fixture Admin")
    property = ResidentialProperty.create!(
      organization: organization,
      name: "Property A",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    unit = Unit.without_auditing do
      Unit.create!(
        organization: organization,
        residential_property: property,
        identifier: "101",
        unit_type: UnitTypes::APARTMENT,
        status: UnitStatuses::AVAILABLE
      )
    end

    audit = TenantAudit.create!(
      organization: organization,
      auditable: unit,
      user: user,
      action: "update",
      audited_changes: { "status" => [ UnitStatuses::AVAILABLE, UnitStatuses::OCCUPIED ] },
      version: 2,
      created_at: Time.zone.parse("2026-03-15 10:30:00")
    )

    entries = Unit::ChangeHistory.new(unit).entries

    assert_equal 1, entries.length
    assert_equal audit.id, entries.first[:id]
    assert_includes entries.first[:description], "Fixture Admin"
    assert_equal "warning", entries.first[:tone]
  end

  test "formats occupancy create audit entry" do
    organization = organizations(:one)
    user = users(:one)
    user.update_columns(name: "Fixture Admin")
    property = ResidentialProperty.create!(
      organization: organization,
      name: "Occupancy History Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    unit = Unit.create!(
      organization: organization,
      residential_property: property,
      identifier: "OCC-201",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    person = Person.create!(
      organization: organization,
      display_name: "History Occupant",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    occupancy = UnitOccupancy.create!(
      organization: organization,
      unit: unit,
      person: person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: OccupancyStatuses::ACTIVE
    )

    audit = TenantAudit.create!(
      organization: organization,
      auditable: occupancy,
      associated: unit,
      user: user,
      action: "create",
      audited_changes: {
        "occupancy_type" => [ nil, OccupancyTypes::TENANT ],
        "person_id" => [ nil, person.id ]
      },
      version: 1,
      created_at: Time.zone.parse("2026-06-14 10:30:00")
    )

    entries = Unit::ChangeHistory.new(unit).entries

    assert entries.any? { |entry| entry[:id] == audit.id }
    entry = entries.find { |item| item[:id] == audit.id }
    assert_includes entry[:description], "History Occupant"
    assert_includes entry[:description], I18n.t("frontend.admin.unit_occupancies.occupancy_types.tenant")
    assert_equal "success", entry[:tone]
  end
end
