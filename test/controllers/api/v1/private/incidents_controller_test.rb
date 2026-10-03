# frozen_string_literal: true

require "test_helper"

# /api/v1/private/incidents — OpenSpec 2026-10-02-incidents.
class Api::V1::Private::IncidentsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_reservation_world("IA")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "a resident reports through their unit and sees only their own reports" do
    request_as(@relative) do
      post api_v1_private_incidents_path, headers: JSON_HEADERS, params: {
        incident: { unit_id: @unit.id, common_area_id: @area.id, category: "maintenance", description: "Luz quemada", priority: "high" }
      }
    end

    assert_response :created
    data = response.parsed_body["data"]
    assert_equal "open", data["status"]
    assert_equal "high", data["priority"]
    assert_equal "Quincho", data.dig("common_area", "name")
    assert_equal @property.name, data.dig("residential_property", "name")

    request_as(@picker) { get api_v1_private_incidents_path, headers: JSON_HEADERS }
    assert_empty response.parsed_body["data"]

    request_as(@relative) { get api_v1_private_incidents_path, headers: JSON_HEADERS }
    assert_equal 1, response.parsed_body["data"].size
    assert_includes response.parsed_body["categories"], "noise"
  end

  test "the concierge reports on the operated property" do
    request_as(@concierge) do
      post api_v1_private_incidents_path, headers: JSON_HEADERS, params: {
        incident: { residential_property_id: @property.id, category: "security", description: "Portón abierto" }
      }
    end

    assert_response :created
  end

  test "reporting elsewhere is forbidden and a missing description is unprocessable" do
    request_as(@relative) do
      post api_v1_private_incidents_path, headers: JSON_HEADERS, params: {
        incident: { residential_property_id: @property_q.id, category: "noise", description: "x" }
      }
    end
    assert_response :forbidden

    request_as(@relative) do
      post api_v1_private_incidents_path, headers: JSON_HEADERS, params: {
        incident: { unit_id: @unit.id, category: "noise", description: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
