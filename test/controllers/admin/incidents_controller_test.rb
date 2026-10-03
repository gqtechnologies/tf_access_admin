# frozen_string_literal: true

require "test_helper"

# /admin/incidents — OpenSpec 2026-10-02-incidents.
class Admin::IncidentsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_reservation_world("WI")
    @incident = Incidents::Report.call(property: @property, actor: @relative,
                                       attributes: { category: "noise", description: "Fiesta hasta tarde" })
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "admin sees the open incidents with counters and assignees" do
    sign_in_as(@property_admin)
    inertia_get admin_incidents_path(property_id: @property.id)

    assert_response :success
    assert_equal "admin/incidents/index", inertia_component
    props = inertia_props
    assert_equal [ @incident.id ], props["incidents"].map { |i| i["id"] }
    assert_equal "Beto Relative", props["incidents"].first["reported_by_name"]
    assert_equal({ "open" => 1, "in_progress" => 0, "closed" => 0 }, props["counters"])
    assert_includes props["assignees"].map { |a| a["name"] }, person_of(@property_admin).display_name
  end

  test "closing with a resolution notifies; without one it is refused" do
    sign_in_as(@property_admin)

    patch admin_incident_path(@incident), params: { incident: { status: "resolved" } }
    assert_equal IncidentStatuses::OPEN, @incident.reload.status

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      patch admin_incident_path(@incident), params: { incident: { status: "resolved", resolution: "Se conversó con la unidad" } }
    end
    assert_equal IncidentStatuses::RESOLVED, @incident.reload.status
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @relative ].each do |user|
      sign_in_as(user)
      get admin_incidents_path

      assert_response :redirect
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
