# frozen_string_literal: true

require "test_helper"

class Admin::UnitOccupancyCreateFlowTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Occupancy Flow Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      identifier: "OCC-FLOW-101",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    @existing_person = Person.create!(
      organization: @organization,
      display_name: "Flow Existing Occupant",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE,
      document_number: "77.777.777-7"
    )
    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "integration-occupancy-flow@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )

    @other_property = ResidentialProperty.create!(
      organization: @organization,
      name: "Other Flow Property",
      property_type: PropertyTypes::BUILDING,
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @other_unit = Unit.create!(
      organization: @organization,
      residential_property: @other_property,
      identifier: "OCC-FLOW-202",
      unit_type: UnitTypes::APARTMENT,
      status: UnitStatuses::AVAILABLE
    )
    UnitOccupancy.create!(
      organization: @organization,
      unit: @other_unit,
      person: @existing_person,
      occupancy_type: OccupancyTypes::OWNER_RESIDENT,
      starts_at: Time.zone.parse("2026-06-01 00:00"),
      status: OccupancyStatuses::ACTIVE
    )

    @occupancies_path = admin_residential_property_unit_occupancies_path(@property, @unit)
    @unit_show_path = admin_residential_property_unit_path(@property, @unit, tab: "occupants")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "create with existing person refreshes occupancies metrics and change history" do
    sign_in_as(@tenant_admin)

    assert_difference -> { @unit.unit_occupancies.count }, 1 do
      post @occupancies_path, params: {
        unit_occupancy: {
          person_id: @existing_person.id,
          occupancy_type: OccupancyTypes::TENANT,
          can_authorize_visits: true,
          starts_at: Date.current
        }
      }
    end

    assert_redirected_to @unit_show_path

    created = @unit.unit_occupancies.find_by!(person_id: @existing_person.id)
    assert created.can_authorize_visits

    inertia_get @unit_show_path
    assert_response :success

    props = inertia_props
    assert props["occupancies"].any? { |occupancy| occupancy["id"] == created.id }
    assert_equal 1, props.dig("unit", "occupancy_stats", "active_occupants_count")
    assert_equal 1, props.dig("unit", "occupancy_stats", "active_authorizers_count")
    assert props["change_history"].any? { |entry| entry["description"].include?(@existing_person.display_name) }
  end

  test "create validation error redirects with inertia form errors" do
    sign_in_as(@tenant_admin)

    assert_no_difference -> { @unit.unit_occupancies.count } do
      post @occupancies_path, params: {
        unit_occupancy: {
          person_id: @existing_person.id,
          occupancy_type: OccupancyTypes::TENANT,
          starts_at: Date.current,
          ends_at: Date.current - 1.day
        }
      }
    end

    assert_redirected_to @unit_show_path
    assert_equal(
      { ends_at: [ validation_key("ends_at_before_starts_at") ] },
      session[:inertia_errors]
    )
  end

  test "destroy soft deletes occupancy and refreshes metrics" do
    sign_in_as(@tenant_admin)

    occupancy = UnitOccupancies::Create.call(
      unit: @unit,
      occupancy_params: {
        person_id: @existing_person.id,
        occupancy_type: OccupancyTypes::TENANT,
        starts_at: Date.current
      },
      actor: @tenant_admin
    )

    delete admin_residential_property_unit_occupancy_path(@property, @unit, occupancy)

    assert_redirected_to @unit_show_path
    assert_nil UnitOccupancy.find_by(id: occupancy.id)

    inertia_get @unit_show_path
    assert_equal 0, inertia_props.dig("unit", "occupancy_stats", "active_occupants_count")
    assert_not inertia_props["occupancies"].any? { |row| row["id"] == occupancy.id }
  end

  test "active_elsewhere returns warning payload for person with occupancy in another unit" do
    sign_in_as(@tenant_admin)

    get active_elsewhere_admin_residential_property_unit_occupancies_path(
      @property,
      @unit,
      person_id: @existing_person.id
    )

    assert_response :success
    payload = JSON.parse(response.body)
    warning = payload["active_elsewhere_occupancies"].first

    assert_equal @other_unit.identifier, warning.dig("unit", "identifier")
    assert_equal @other_property.name, warning.dig("property", "name")
    assert_equal OccupancyTypes::OWNER_RESIDENT, warning["occupancy_type"]
    assert warning["starts_at"].present?
    assert_equal I18n.t("frontend.admin.unit_occupancies.occupancy_types.owner_resident"), warning["occupancy_type_label"]
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: {
      user: { email: user.email, password: "password1" }
    }
  end

  def validation_key(name)
    "admin.unit_occupancies.validations.#{name}"
  end
end
