# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/migrate/20260614120000_prepare_unit_occupancies_for_management.rb")

class PrepareUnitOccupanciesForManagementTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @migration = PrepareUnitOccupanciesForManagement.new

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Migration Occupancy Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      identifier: "OCC-MIG-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "migrate_legacy_occupancy_types maps owner to owner_resident" do
    occupancy = create_occupancy_with_legacy_type!("owner")

    @migration.migrate_legacy_occupancy_types!

    assert_equal OccupancyTypes::OWNER_RESIDENT, occupancy.reload.occupancy_type
  end

  test "migrate_legacy_occupancy_types maps family to family_member" do
    occupancy = create_occupancy_with_legacy_type!("family")

    @migration.migrate_legacy_occupancy_types!

    assert_equal OccupancyTypes::FAMILY_MEMBER, occupancy.reload.occupancy_type
  end

  test "migrate_legacy_occupancy_types leaves tenant and other unchanged" do
    tenant = create_occupancy_with_legacy_type!("tenant")
    other = create_occupancy_with_legacy_type!("other")

    @migration.migrate_legacy_occupancy_types!

    assert_equal "tenant", tenant.reload.occupancy_type
    assert_equal "other", other.reload.occupancy_type
  end

  private

  def create_occupancy_with_legacy_type!(legacy_type)
    person = Person.create!(
      organization: @organization,
      display_name: "Legacy #{legacy_type} occupant",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    occupancy = UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: OccupancyStatuses::ACTIVE
    )
    occupancy.update_column(:occupancy_type, legacy_type)
    occupancy
  end
end
