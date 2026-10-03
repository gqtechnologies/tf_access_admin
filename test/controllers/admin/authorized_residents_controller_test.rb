# frozen_string_literal: true

require "test_helper"

# /admin/authorized_residents — OpenSpec 2026-10-02-authorized-residents.
class Admin::AuthorizedResidentsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_reservation_world("WAR")
    UnitOccupancy.where(person: person_of(@picker)).update_all(can_authorize_visits: true)
    @record = AuthorizedResidents::Propose.call(unit: @unit, proposer: person_of(@picker),
                                                person_params: { name: "Nora Nana", email: "nora@example.test", document: "1-1" })
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "admin sees pending proposals and approves them" do
    sign_in_as(@property_admin)
    inertia_get admin_authorized_residents_path(property_id: @property.id)

    assert_response :success
    assert_equal "admin/authorized_residents/index", inertia_component
    assert_equal [ "Nora Nana" ], inertia_props["authorized_residents"].map { |r| r["name"] }
    assert_equal "Ana Picker", inertia_props["authorized_residents"].first["proposed_by_name"]
    assert_equal({ "pending" => 1, "active" => 0, "closed" => 0 }, inertia_props["counters"])

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      post approve_admin_authorized_resident_path(@record)
    end
    assert_equal AuthorizedResidentStatuses::ACTIVE, @record.reload.status

    post revoke_admin_authorized_resident_path(@record)
    assert_equal AuthorizedResidentStatuses::REVOKED, @record.reload.status
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @picker ].each do |user|
      sign_in_as(user)
      get admin_authorized_residents_path

      assert_response :redirect
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
