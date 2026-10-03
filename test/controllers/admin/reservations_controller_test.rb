# frozen_string_literal: true

require "test_helper"

# /admin/common_areas and /admin/reservations — OpenSpec 2026-10-02-common-area-reservations.
class Admin::ReservationsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_reservation_world("WR")
    @pending = book
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "admin lists pending reservations with counters" do
    sign_in_as(@property_admin)
    inertia_get admin_reservations_path(property_id: @property.id)

    assert_response :success
    assert_equal "admin/reservations/index", inertia_component
    assert_equal [ @pending.id ], inertia_props["reservations"].map { |r| r["id"] }
    assert_equal({ "pending" => 1, "upcoming" => 0, "history" => 0 }, inertia_props["counters"])
    assert_equal "Bea Booker", inertia_props["reservations"].first["requested_by_name"]
  end

  test "approve and reject push the outcome" do
    sign_in_as(@property_admin)

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      post approve_admin_reservation_path(@pending)
    end
    assert_equal ReservationStatuses::APPROVED, @pending.reload.status

    other = ActsAsTenant.with_tenant(@organization) { book(from: local_at(4, 18), to: local_at(4, 20)) }
    ActsAsTenant.current_tenant = nil
    post reject_admin_reservation_path(other), params: { reason: "Ocupado por la comunidad" }
    assert_equal ReservationStatuses::REJECTED, other.reload.status
    assert_equal "Ocupado por la comunidad", other.rejection_reason
  end

  test "admin cancels an upcoming approved reservation" do
    ActsAsTenant.with_tenant(@organization) { Reservations::Decide.call(reservation: @pending, actor: @tenant_admin, decision: :approve) }
    ActsAsTenant.current_tenant = nil
    sign_in_as(@tenant_admin)

    post cancel_admin_reservation_path(@pending)

    assert_equal ReservationStatuses::CANCELLED, @pending.reload.status
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @booker ].each do |user|
      sign_in_as(user)
      get admin_reservations_path

      assert_response :redirect
    end
  end

  test "common areas page lists areas with rules" do
    ActsAsTenant.with_tenant(@organization) do
      @area.common_area_rules.create!(organization: @organization, rule_type: "max_duration_minutes", value_int: 240)
    end
    ActsAsTenant.current_tenant = nil
    sign_in_as(@tenant_admin)

    inertia_get admin_common_areas_path(property_id: @property.id)

    assert_response :success
    area = inertia_props["common_areas"].sole
    assert_equal "Quincho", area["name"]
    assert_equal({ "max_duration_minutes" => 240 }, area["rules"])
    assert_equal 1, area["upcoming_count"]
  end

  test "creates an area with rules, and blank rules are removed on update" do
    sign_in_as(@tenant_admin)

    post admin_common_areas_path(property_id: @property.id), params: {
      common_area: { name: "Piscina", area_type: "pool", capacity: 20, requires_approval: false,
                     rules: { opens_at: "09:00", closes_at: "20:00", max_duration_minutes: "120", notes: "Usar gorro" } }
    }

    area = ActsAsTenant.with_tenant(@organization) { CommonArea.find_by!(name: "Piscina") }
    assert_not area.requires_approval?
    assert_equal({ "opens_at" => "09:00", "closes_at" => "20:00", "max_duration_minutes" => 120, "notes" => "Usar gorro" },
                 ActsAsTenant.with_tenant(@organization) { area.reload.rules })

    patch admin_common_area_path(area), params: { common_area: { rules: { notes: "", max_duration_minutes: "90" } } }
    assert_equal({ "opens_at" => "09:00", "closes_at" => "20:00", "max_duration_minutes" => 90 },
                 ActsAsTenant.with_tenant(@organization) { area.reload.rules })
  end

  test "invalid rules store nothing" do
    sign_in_as(@tenant_admin)

    assert_no_difference -> { ActsAsTenant.with_tenant(@organization) { CommonArea.count } } do
      post admin_common_areas_path(property_id: @property.id), params: {
        common_area: { name: "Mala", area_type: "gym", rules: { opens_at: "22:00", closes_at: "08:00" } }
      }
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
