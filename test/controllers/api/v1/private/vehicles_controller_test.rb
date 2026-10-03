# frozen_string_literal: true

require "test_helper"

# /api/v1/private/units/:unit_id/vehicles and /concierge/vehicles — OpenSpec 2026-10-02-vehicles.
class Api::V1::Private::VehiclesControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_reservation_world("VH")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "a resident registers a vehicle with a normalized plate and the unit lists it" do
    request_as(@relative) do
      post api_v1_private_unit_vehicles_path(@unit), headers: JSON_HEADERS, params: {
        vehicle: { plate_number: "ab-cd 12", vehicle_type: "car", brand: "Toyota", model: "Yaris", color: "Rojo" }
      }
    end

    assert_response :created
    assert_equal "ABCD12", response.parsed_body.dig("data", "plate_number")
    assert_equal "Beto Relative", response.parsed_body.dig("data", "owner_name")

    request_as(@owner) { get api_v1_private_unit_vehicles_path(@unit), headers: JSON_HEADERS }
    assert_equal [ "ABCD12" ], response.parsed_body["data"].map { |v| v["plate_number"] }
    assert_includes response.parsed_body["vehicle_types"], "motorcycle"
  end

  test "a plate is unique in the organization and must be valid" do
    create_vehicle("ABCD12")

    request_as(@relative) do
      post api_v1_private_unit_vehicles_path(@unit), headers: JSON_HEADERS, params: { vehicle: { plate_number: "abcd-12" } }
    end
    assert_response :unprocessable_entity

    request_as(@relative) do
      post api_v1_private_unit_vehicles_path(@unit), headers: JSON_HEADERS, params: { vehicle: { plate_number: "--" } }
    end
    assert_response :unprocessable_entity
  end

  test "residents remove a vehicle and strangers cannot touch the unit" do
    vehicle = create_vehicle("XY9988")

    request_as(@owner) { delete api_v1_private_unit_vehicle_path(@unit, vehicle), headers: JSON_HEADERS }
    assert_response :no_content
    assert ActsAsTenant.with_tenant(@organization) { Vehicle.with_deleted.find(vehicle.id).deleted_at.present? }

    request_as(parcel_member("vh-stranger@example.test", "Stranger")) do
      get api_v1_private_unit_vehicles_path(@unit), headers: JSON_HEADERS
    end
    assert_response :not_found
  end

  test "the front desk finds a vehicle by part of the plate in its property only" do
    create_vehicle("ABCD12")
    ActsAsTenant.with_tenant(@organization) do
      Vehicle.create!(organization: @organization, unit: @unit_q, plate_number: "ABCD99", status: "active")
    end
    ActsAsTenant.current_tenant = nil

    request_as(@concierge) do
      get api_v1_private_concierge_vehicles_path, params: { property_id: @property.id, plate: "cd-1" }, headers: JSON_HEADERS
    end
    assert_response :ok
    assert_equal [ "ABCD12" ], response.parsed_body["data"].map { |v| v["plate_number"] }
    assert_equal "VH-P-101", response.parsed_body["data"].first.dig("unit", "name")

    request_as(@concierge) do
      get api_v1_private_concierge_vehicles_path, params: { property_id: @property.id, plate: "" }, headers: JSON_HEADERS
    end
    assert_empty response.parsed_body["data"]

    request_as(@relative) do
      get api_v1_private_concierge_vehicles_path, params: { property_id: @property.id, plate: "AB" }, headers: JSON_HEADERS
    end
    assert_response :forbidden
  end

  private

  def create_vehicle(plate)
    vehicle = ActsAsTenant.with_tenant(@organization) do
      Vehicle.create!(organization: @organization, unit: @unit, person: person_of(@relative), plate_number: plate, status: "active")
    end
    ActsAsTenant.current_tenant = nil
    vehicle
  end

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
