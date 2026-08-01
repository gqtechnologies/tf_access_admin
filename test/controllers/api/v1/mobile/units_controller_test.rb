# frozen_string_literal: true

require "test_helper"

class Api::V1::Mobile::UnitsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = organizations(:one)
    @other_org    = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Mobile Units Property")
    @unit     = create_unit(@property, "MU-101")

    @resident = create_user_for_organization(
      organization: @organization,
      email: "mobile-units-resident@example.test",
      role: AvailableRoles::CLIENT
    )
    UnitOccupancy.create!(
      organization: @organization,
      person: @resident.person_for(@organization),
      unit: @unit,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE,
      can_authorize_visits: true
    )

    @no_auth_resident = create_user_for_organization(
      organization: @organization,
      email: "mobile-units-no-auth@example.test",
      role: AvailableRoles::CLIENT
    )
    UnitOccupancy.create!(
      organization: @organization,
      person: @no_auth_resident.person_for(@organization),
      unit: @unit,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE,
      can_authorize_visits: false
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "resident with active occupancy sees the unit" do
    sign_in @resident

    get api_v1_mobile_units_path

    assert_response :ok
    ids = response.parsed_body["data"].map { |entry| entry["id"] }
    assert_includes ids, @unit.id
  end

  test "unit without authorize_visits is excluded" do
    sign_in @no_auth_resident

    get api_v1_mobile_units_path

    assert_response :ok
    ids = response.parsed_body["data"].map { |entry| entry["id"] }
    assert_not_includes ids, @unit.id
  end

  test "units across organizations are all returned" do
    other_unit = ActsAsTenant.with_tenant(@other_org) do
      other_property = create_property(@other_org, "Mobile Units Other Org Property")
      unit = create_unit(other_property, "MU-OO-201")
      person = @resident.person_for(@other_org) ||
        Person.create!(organization: @other_org, display_name: @resident.name, user: @resident, person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE)
      UnitOccupancy.create!(
        organization: @other_org,
        person: person,
        unit: unit,
        occupancy_type: OccupancyTypes::TENANT,
        starts_at: 7.days.ago,
        status: OccupancyStatuses::ACTIVE,
        can_authorize_visits: true
      )
      unit
    end

    sign_in @resident

    get api_v1_mobile_units_path

    assert_response :ok
    ids = response.parsed_body["data"].map { |entry| entry["id"] }
    assert_includes ids, @unit.id
    assert_includes ids, other_unit.id
  end

  test "user with no eligible units gets an empty list" do
    stranger = create_user_for_organization(
      organization: @organization,
      email: "mobile-units-stranger@example.test",
      role: AvailableRoles::CLIENT
    )
    sign_in stranger

    get api_v1_mobile_units_path

    assert_response :ok
    assert_equal [], response.parsed_body["data"]
  end

  test "unauthenticated request is rejected" do
    get api_v1_mobile_units_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end
end
