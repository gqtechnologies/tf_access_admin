# frozen_string_literal: true

require "test_helper"

class Admin::ResidentialProperties::UnitOccupanciesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Occupancies Controller Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      identifier: "OCC-CTRL-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    @person = Person.create!(
      organization: @organization,
      display_name: "Occupancies Controller Person",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    @occupancy = UnitOccupancy.create!(
      organization: @organization,
      unit: @unit,
      person: @person,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: Time.current,
      status: "active"
    )

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "tenant-admin-occupancies@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )

    @non_admin = create_user_for_organization(
      organization: @organization,
      email: "non-admin-occupancies@example.test",
      role: AvailableRoles::CLIENT
    )

    @occupancies_path = admin_residential_property_unit_occupancies_path(@property, @unit)
    @occupancy_path = admin_residential_property_unit_occupancy_path(@property, @unit, @occupancy)
    @unit_show_path = admin_residential_property_unit_path(@property, @unit, tab: "occupants")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "create is forbidden for non-admin users" do
    sign_in_as(@non_admin)

    assert_no_difference -> { @unit.unit_occupancies.count } do
      post @occupancies_path, params: {
        unit_occupancy: {
          person_id: @person.id,
          occupancy_type: OccupancyTypes::TENANT,
          starts_at: Time.current
        }
      }
    end

    assert_redirected_to admin_residential_properties_path
  end

  test "update is forbidden for non-admin users" do
    sign_in_as(@non_admin)

    assert_no_changes -> { @occupancy.reload.occupancy_type } do
      patch @occupancy_path, params: {
        unit_occupancy: { occupancy_type: OccupancyTypes::FAMILY_MEMBER }
      }
    end

    assert_redirected_to admin_residential_properties_path
  end

  test "destroy is forbidden for non-admin users" do
    sign_in_as(@non_admin)

    assert_no_difference -> { @unit.unit_occupancies.count } do
      delete @occupancy_path
    end

    assert_redirected_to admin_residential_properties_path
  end

  test "create is forbidden for tenant admin from another organization" do
    other_organization = organizations(:two)
    other_property = ActsAsTenant.without_tenant do
      ResidentialProperty.create!(
        organization: other_organization,
        name: "Other Org Occupancies Property",
        property_type: PropertyTypes::BUILDING,
        status: "active",
        country: "Chile",
        timezone: "America/Santiago"
      )
    end
    other_unit = ActsAsTenant.without_tenant do
      Unit.create!(
        organization: other_organization,
        residential_property: other_property,
        identifier: "OTH-OCC-CTRL-101",
        unit_type: UnitTypes::APARTMENT,
        status: UnitStatuses::AVAILABLE
      )
    end
    other_person = ActsAsTenant.without_tenant do
      Person.create!(
        organization: other_organization,
        display_name: "Other Org Occupancies Person",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
    end

    sign_in_as(@tenant_admin)

    assert_no_difference -> { UnitOccupancy.unscoped.count } do
      post admin_residential_property_unit_occupancies_path(other_property, other_unit), params: {
        unit_occupancy: {
          person_id: other_person.id,
          occupancy_type: OccupancyTypes::TENANT,
          starts_at: Time.current
        }
      }
    end

    assert_redirected_to admin_residential_properties_path
  end

  test "tenant admin create delegates to service layer" do
    sign_in_as(@tenant_admin)

    assert_raises(NotImplementedError) do
      post @occupancies_path, params: {
        unit_occupancy: {
          person_id: @person.id,
          occupancy_type: OccupancyTypes::TENANT,
          can_authorize_visits: true,
          starts_at: Time.current
        }
      }
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: {
      user: { email: user.email, password: "password1" }
    }
  end
end
