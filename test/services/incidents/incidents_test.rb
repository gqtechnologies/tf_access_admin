# frozen_string_literal: true

require "test_helper"

class IncidentsServicesTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup { setup_reservation_world("IN") }

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "a resident reports on their property, naming their unit and a common area" do
    incident = report(@relative, unit: @unit, common_area: @area, category: "maintenance", description: "Gotera en el quincho")

    assert incident.persisted?
    assert_equal IncidentStatuses::OPEN, incident.status
    assert_equal Priorities::NORMAL, incident.priority
    assert_equal person_of(@relative).id, incident.reported_by_person_id
    assert_equal [ nil, "open" ], incident.incident_status_histories.sole.then { |h| [ h.from_status, h.to_status ] }
  end

  test "owners report too, but nobody names a unit that is not theirs" do
    assert report(@owner).persisted?

    other_unit = create_unit(@property, "IN-P-999")
    assert_raises(Incidents::Report::NotAllowed) { report(@relative, unit: other_unit) }
  end

  test "people without a unit in the property cannot report, the concierge can" do
    assert_raises(Incidents::Report::NotAllowed) { report(parcel_member("in-stranger@example.test", "Stranger")) }
    assert_raises(Incidents::Report::NotAllowed) { report(@relative, property: @property_q) }

    assert report(@concierge, category: "security", description: "Portón trabado").persisted?
  end

  test "a common area of another property is rejected" do
    foreign = create_area(property: @property_q, name: "Otra")

    assert_raises(ActiveRecord::RecordInvalid) { report(@relative, common_area: foreign) }
  end

  test "the administration moves it and closing it tells the reporter" do
    incident = report(@relative)

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      Incidents::Update.call(incident: incident, actor: @property_admin,
                             attributes: { status: "in_progress", assigned_to_person_id: person_of(@property_admin).id })
    end
    assert_equal person_of(@property_admin).id, incident.reload.assigned_to_person_id

    assert_raises(Incidents::Update::ResolutionRequired) do
      Incidents::Update.call(incident: incident, actor: @property_admin, attributes: { status: "resolved" })
    end

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      Incidents::Update.call(incident: incident.reload, actor: @property_admin,
                             attributes: { status: "resolved", resolution: "Se cambió la canaleta" })
    end
    incident.reload
    assert incident.resolved_at.present?
    assert_equal 3, incident.incident_status_histories.count

    payload = Notifications::PushPayload.build(incident.notifications.order(:created_at).last)
    assert_equal "incident", payload[:data][:type]
    assert_equal "resolved", payload[:data][:status]
    assert_includes payload[:body], "Se cambió la canaleta"
  end

  test "changing only the priority does not notify, and only managers may update" do
    incident = report(@relative)

    assert_no_enqueued_jobs only: DeliverPushNotificationJob do
      Incidents::Update.call(incident: incident, actor: @tenant_admin, attributes: { priority: "urgent" })
    end

    [ @concierge, @relative ].each do |actor|
      assert_raises(Pundit::NotAuthorizedError) do
        Incidents::Update.call(incident: incident, actor: actor, attributes: { status: "in_progress" })
      end
    end
  end

  private

  def report(user, property: @property, unit: nil, common_area: nil, category: "noise", description: "Ruido a las 3 am")
    Incidents::Report.call(property: property, unit: unit, common_area: common_area, actor: user,
                           attributes: { category: category, description: description })
  end
end
