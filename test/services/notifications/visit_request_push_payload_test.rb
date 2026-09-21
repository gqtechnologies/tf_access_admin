# frozen_string_literal: true

require "test_helper"

module Notifications
  # fcm-push-notifications "Visit request payload carries unit and property ids".
  class VisitRequestPushPayloadTest < ActiveSupport::TestCase
    include OperationalPolicyTestHelper

    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      Current.organization = @organization

      @property = create_property(@organization, "Request Payload Property")
      @unit = create_unit(@property, "VRP-101")
      @resident = create_user_for_organization(
        organization: @organization, email: "vrp-resident@example.test", role: AvailableRoles::CLIENT
      )
      visitor = Person.create!(
        organization: @organization, display_name: "Payload Visitor",
        person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
      )
      @visit = Visit.create!(
        organization: @organization, unit: @unit, visitor_person: visitor,
        scheduled_at: 1.day.from_now, status: VisitStatuses::PENDING, visit_type: VisitTypes::GUEST
      )
      @notification = Notification.create!(
        organization: @organization, recipient_person: @resident.person_for(@organization),
        unit: @unit, residential_property: @property, notifiable: @visit,
        notification_type: NotificationTypes::VISIT_REQUEST,
        channel: NotificationChannels::PUSH, status: NotificationStatuses::PENDING
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
      Current.reset
    end

    test "data carries the visit, unit and property ids" do
      data = VisitRequestPushPayload.build(@notification)[:data]

      assert_equal NotificationTypes::VISIT_REQUEST, data[:type]
      assert_equal @visit.id, data[:visit_id]
      assert_equal @unit.id, data[:unit_id]
      assert_equal @property.id, data[:residential_property_id]
      assert_equal "Payload Visitor", data[:visitor_name]
    end
  end
end
