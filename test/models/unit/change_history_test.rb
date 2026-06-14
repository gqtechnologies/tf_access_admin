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
end
