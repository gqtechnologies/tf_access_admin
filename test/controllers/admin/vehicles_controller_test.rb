# frozen_string_literal: true

require "test_helper"

# /admin/vehicles — OpenSpec 2026-10-02-vehicles.
class Admin::VehiclesControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ReservationTestHelper

  setup do
    setup_reservation_world("WV")
    @vehicle = Vehicle.create!(organization: @organization, unit: @unit, person: person_of(@relative), plate_number: "GHJK55", status: "active")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "admin lists and searches the property's vehicles and removes one" do
    sign_in_as(@property_admin)

    inertia_get admin_vehicles_path(property_id: @property.id)
    assert_response :success
    assert_equal "admin/vehicles/index", inertia_component
    assert_equal [ "GHJK55" ], inertia_props["vehicles"].map { |v| v["plate_number"] }

    inertia_get admin_vehicles_path(property_id: @property.id, q: { query: "zz" })
    assert_empty inertia_props["vehicles"]

    delete admin_vehicle_path(@vehicle)
    assert ActsAsTenant.with_tenant(@organization) { Vehicle.with_deleted.find(@vehicle.id).deleted_at.present? }
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @relative ].each do |user|
      sign_in_as(user)
      get admin_vehicles_path

      assert_response :redirect
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
