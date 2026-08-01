# frozen_string_literal: true

require "test_helper"

# Integration tests for POST /api/v1/mobile/units/:unit_id/visits.
# Runs with no request subdomain/host set to prove tenant resolution comes
# entirely from the unit, not from an ambient/request-derived tenant.
class Api::V1::Mobile::Units::VisitsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = organizations(:one)
    @other_org    = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Mobile Visits Property")
    @unit     = create_unit(@property, "MV-101")

    @resident = create_user_for_organization(
      organization: @organization,
      email: "mobile-visits-resident@example.test",
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

    @other_unit_resident = create_user_for_organization(
      organization: @organization,
      email: "mobile-visits-other-unit@example.test",
      role: AvailableRoles::CLIENT
    )
    other_unit_same_org = create_unit(@property, "MV-102")
    UnitOccupancy.create!(
      organization: @organization,
      person: @other_unit_resident.person_for(@organization),
      unit: other_unit_same_org,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE,
      can_authorize_visits: true
    )

    @stranger = create_user_for_organization(
      organization: @organization,
      email: "mobile-visits-stranger@example.test",
      role: AvailableRoles::CLIENT
    )

    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "authorized resident creates a visit for their unit with no subdomain set" do
    post_visit(user: @resident, unit: @unit)

    assert_response :created
    body = response.parsed_body
    assert_equal VisitStatuses::AUTHORIZED, body.dig("data", "status")

    visit = Visit.unscoped.find(body.dig("data", "id"))
    assert_equal @organization.id, visit.organization_id
    assert_equal @unit.id, visit.unit_id
  end

  test "user with no relationship to the unit's organization is denied" do
    person_less_user = create_user_for_organization(
      organization: @other_org,
      email: "mobile-visits-no-org@example.test",
      role: AvailableRoles::CLIENT
    )

    post_visit(user: person_less_user, unit: @unit)

    assert_response :forbidden
  end

  test "user with a relationship in the organization but not on this unit is denied" do
    post_visit(user: @other_unit_resident, unit: @unit)

    assert_response :forbidden
  end

  test "invalid visitor payload is rejected" do
    sign_in @resident

    post api_v1_mobile_unit_visits_path(unit_id: @unit.id),
         params:  { visit: { scheduled_at: nil, visitor: { name: "", document: "", phone: "" } } }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unprocessable_entity
    sign_out @resident
  end

  test "unauthenticated request is rejected" do
    post api_v1_mobile_unit_visits_path(unit_id: @unit.id),
         params:  { visit: {} }.to_json,
         headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :unauthorized
  end

  private

  def post_visit(user:, unit:)
    payload = {
      visit: {
        scheduled_at: 2.hours.from_now.iso8601,
        visitor: { name: "Test Visitor", document: "DOC-#{SecureRandom.hex(4)}", phone: "+56912345678" }
      }
    }

    sign_in user

    post api_v1_mobile_unit_visits_path(unit_id: unit.id),
         params:  payload.to_json,
         headers: { "Content-Type" => "application/json" }

    sign_out user
  end
end
