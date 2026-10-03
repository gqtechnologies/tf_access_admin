# frozen_string_literal: true

require "test_helper"

# /api/v1/private/{common_areas,reservations} — OpenSpec 2026-10-02-common-area-reservations.
class Api::V1::Private::ReservationsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_reservation_world("RA")
    @area.common_area_rules.create!(organization: @organization, rule_type: "opens_at", value_text: "10:00")
    create_area(name: "Cerrada", status: CommonArea::STATUS_INACTIVE)
    create_area(property: @property_q, name: "Otra propiedad")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "lists the active areas of the unit's property with rules and the permission" do
    request_as(@booker) { get api_v1_private_common_areas_path(unit_id: @unit.id), headers: JSON_HEADERS }

    assert_response :ok
    body = response.parsed_body
    assert_equal [ "Quincho" ], body["data"].map { |a| a["name"] }
    assert_equal({ "opens_at" => "10:00" }, body["data"].first["rules"])
    assert_equal true, body["data"].first["requires_approval"]
    assert_equal true, body["can_reserve"]
    assert_equal "America/Santiago", body["time_zone"]
  end

  test "residents without the permission see the areas but cannot reserve" do
    request_as(@relative) { get api_v1_private_common_areas_path(unit_id: @unit.id), headers: JSON_HEADERS }

    assert_equal false, response.parsed_body["can_reserve"]
  end

  test "availability lists the slots taken that day" do
    ActsAsTenant.with_tenant(@organization) { book(from: local_at(3, 18), to: local_at(3, 21)) }
    ActsAsTenant.current_tenant = nil
    day = local_at(3, 0).to_date.iso8601

    request_as(@relative) { get availability_api_v1_private_common_area_path(@area, day: day), headers: JSON_HEADERS }

    assert_response :ok
    assert_equal 1, response.parsed_body["data"].size
    assert_equal "pending", response.parsed_body["data"].first["status"]
  end

  test "creates a reservation" do
    request_as(@booker) do
      post api_v1_private_reservations_path, headers: JSON_HEADERS, params: {
        reservation: { unit_id: @unit.id, common_area_id: @area.id,
                       starts_at: local_at(3, 18).iso8601, ends_at: local_at(3, 21).iso8601, guest_count: 8 }
      }
    end

    assert_response :created
    data = response.parsed_body["data"]
    assert_equal "pending", data["status"]
    assert_equal "Quincho", data.dig("common_area", "name")
    assert_equal true, data["can_cancel"]
  end

  test "a rule violation is a 422 with its code, a taken slot a 409, no permission a 403" do
    request_as(@booker) do
      post api_v1_private_reservations_path, headers: JSON_HEADERS, params: {
        reservation: { unit_id: @unit.id, common_area_id: @area.id, starts_at: local_at(3, 8).iso8601, ends_at: local_at(3, 9).iso8601 }
      }
    end
    assert_response :unprocessable_entity
    assert_equal "opening_hours", response.parsed_body["code"]

    ActsAsTenant.with_tenant(@organization) { book(from: local_at(3, 18), to: local_at(3, 21)) }
    ActsAsTenant.current_tenant = nil
    request_as(@booker) do
      post api_v1_private_reservations_path, headers: JSON_HEADERS, params: {
        reservation: { unit_id: @unit.id, common_area_id: @area.id, starts_at: local_at(3, 19).iso8601, ends_at: local_at(3, 20).iso8601 }
      }
    end
    assert_response :conflict
    assert_equal "slot_taken", response.parsed_body["code"]

    request_as(@relative) do
      post api_v1_private_reservations_path, headers: JSON_HEADERS, params: {
        reservation: { unit_id: @unit.id, common_area_id: @area.id, starts_at: local_at(5, 18).iso8601, ends_at: local_at(5, 19).iso8601 }
      }
    end
    assert_response :forbidden
  end

  test "lists the unit's reservations and lets the booker cancel" do
    reservation = ActsAsTenant.with_tenant(@organization) { book }
    ActsAsTenant.current_tenant = nil

    request_as(@relative) { get api_v1_private_reservations_path(unit_id: @unit.id), headers: JSON_HEADERS }
    assert_equal [ reservation.id ], response.parsed_body["data"].map { |r| r["id"] }
    assert_equal false, response.parsed_body["data"].first["can_cancel"]

    request_as(@relative) { post cancel_api_v1_private_reservation_path(reservation), headers: JSON_HEADERS }
    assert_response :forbidden

    request_as(@booker) { post cancel_api_v1_private_reservation_path(reservation), headers: JSON_HEADERS }
    assert_response :ok
    assert_equal "cancelled", response.parsed_body.dig("data", "status")
  end

  test "a unit without relationship is not found" do
    request_as(parcel_member("ra-stranger@example.test", "Stranger")) do
      get api_v1_private_common_areas_path(unit_id: @unit.id), headers: JSON_HEADERS
    end

    assert_response :not_found
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
