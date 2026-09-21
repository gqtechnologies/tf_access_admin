# frozen_string_literal: true

require "test_helper"

module Notifications
  # fcm-push-notifications "Entry denied push payload".
  class VisitEntryDeniedPushPayloadTest < ActiveSupport::TestCase
    include OperationalPolicyTestHelper

    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      Current.organization = @organization

      @property = create_property(@organization, "Denied Payload Property")
      @unit = create_unit(@property, "VED-101")
      @host = create_user_for_organization(
        organization: @organization, email: "ved-host@example.test", role: AvailableRoles::CLIENT
      )
      @host.update!(language: Languages::EN)
      visitor = Person.create!(
        organization: @organization, display_name: "Denied Visitor",
        person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
      )
      @visit = Visit.create!(
        organization: @organization, unit: @unit, visitor_person: visitor,
        scheduled_at: 10.minutes.ago, status: VisitStatuses::AUTHORIZED, visit_type: VisitTypes::GUEST,
        created_by: @host, authorized_by: @host
      )
      @notification = Notification.create!(
        organization: @organization, recipient_person: @host.person_for(@organization),
        unit: @unit, residential_property: @property, notifiable: @visit,
        notification_type: NotificationTypes::VISIT_ENTRY_DENIED,
        channel: NotificationChannels::PUSH, status: NotificationStatuses::PENDING
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
      Current.reset
    end

    test "names the visitor in the recipient language and carries the navigation ids" do
      payload = VisitEntryDeniedPushPayload.build(@notification)

      assert_equal "Entry denied", payload[:title]
      assert_includes payload[:body], "Denied Visitor"
      assert_equal NotificationTypes::VISIT_ENTRY_DENIED, payload[:data][:type]
      assert_equal @visit.id, payload[:data][:visit_id]
      assert_equal @unit.id, payload[:data][:unit_id]
      assert_equal @property.id, payload[:data][:residential_property_id]
    end
  end
end
