# frozen_string_literal: true

require "test_helper"

# /api/v1/private/concierge/shift and /admin/staff_shifts — OpenSpec 2026-10-02-staff-shifts.
class Api::V1::Private::Concierge::ShiftsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include InertiaTestHelper
  include ReservationTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_reservation_world("SH")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "the concierge opens a shift, parcels attach to it, and closing leaves the handover" do
    request_as(@concierge) { get api_v1_private_concierge_shift_path(property_id: @property.id), headers: JSON_HEADERS }
    assert_response :ok
    assert_nil response.parsed_body.dig("data", "current")

    request_as(@concierge) { post api_v1_private_concierge_shift_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    assert_response :created
    assert response.parsed_body.dig("data", "current", "started_at").present?

    parcel = ActsAsTenant.with_tenant(@organization) { Parcels::Receive.call(unit: @unit, actor: @concierge) }
    ActsAsTenant.current_tenant = nil
    shift = ActsAsTenant.with_tenant(@organization) { StaffShift.open_now.sole }
    assert_equal shift.id, parcel.reload.staff_shift_id

    request_as(@concierge) { get api_v1_private_concierge_shift_path(property_id: @property.id), headers: JSON_HEADERS }
    assert_equal 1, response.parsed_body.dig("data", "current", "parcels_received")

    request_as(@concierge) do
      post close_api_v1_private_concierge_shift_path, params: { property_id: @property.id, notes: "Portón lento" }, headers: JSON_HEADERS
    end
    assert_response :ok
    assert_nil response.parsed_body.dig("data", "current")
    assert_equal "Portón lento", response.parsed_body.dig("data", "last_handover", "notes")
    assert_equal StaffShiftStatuses::COMPLETED, shift.reload.status
  end

  test "one open shift at a time, and closing without one is refused" do
    request_as(@concierge) do
      post close_api_v1_private_concierge_shift_path, params: { property_id: @property.id }, headers: JSON_HEADERS
    end
    assert_response :unprocessable_entity

    request_as(@concierge) { post api_v1_private_concierge_shift_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    request_as(@concierge) { post api_v1_private_concierge_shift_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    assert_response :unprocessable_entity
  end

  test "residents and properties not operated are refused" do
    request_as(@relative) { post api_v1_private_concierge_shift_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    assert_response :forbidden

    request_as(@concierge) { post api_v1_private_concierge_shift_path, params: { property_id: @property_q.id }, headers: JSON_HEADERS }
    assert_response :forbidden
  end

  test "the admin reads the day's shift log with parcels received" do
    ActsAsTenant.with_tenant(@organization) do
      shift = StaffShifts::Open.call(property: @property, actor: @concierge)
      Parcels::Receive.call(unit: @unit, actor: @concierge)
      StaffShifts::Close.call(shift: shift, actor: @concierge, notes: "Sin novedad")
    end
    ActsAsTenant.current_tenant = nil

    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: @property_admin.email, password: "Password1@" } }
    inertia_get admin_staff_shifts_path(property_id: @property.id)

    assert_response :success
    assert_equal "admin/staff_shifts/index", inertia_component
    row = inertia_props["shifts"].sole
    assert_equal "completed", row["status"]
    assert_equal "Sin novedad", row["notes"]
    assert_equal 1, row["parcels_received"]
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
