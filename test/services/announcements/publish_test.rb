# frozen_string_literal: true

require "test_helper"

class Announcements::PublishTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include AnnouncementTestHelper
  include ActiveJob::TestHelper

  setup { setup_announcement_world("AP") }

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "publishes a draft and pushes it once to every resident of the property" do
    # The owner also lives there: still one notification for them.
    parcel_occupy(@owner, @unit, type: OccupancyTypes::OWNER_RESIDENT)
    other_unit_resident = parcel_member("ap-other@example.test", "Otro Depto")
    parcel_occupy(other_unit_resident, create_unit(@property, "AP-P-202"))
    outsider = parcel_member("ap-outsider@example.test", "Otra Propiedad")
    parcel_occupy(outsider, @unit_q)

    announcement = create_announcement

    assert_enqueued_jobs 4, only: DeliverPushNotificationJob do
      Announcements::Publish.call(announcement: announcement, actor: @tenant_admin)
    end

    announcement.reload
    assert_equal AnnouncementStatuses::PUBLISHED, announcement.status
    assert announcement.published_at.present?

    recipients = announcement.notifications.map(&:recipient_person_id)
    assert_equal [ @picker, @relative, @owner, other_unit_resident ].map { |u| person_of(u).id }.sort, recipients.sort
    assert announcement.notifications.all? { |n| n.notification_type == NotificationTypes::ANNOUNCEMENT }
  end

  test "push payload carries the title, a short body and the announcement id" do
    announcement = create_announcement(content: "A" * 300)
    Announcements::Publish.call(announcement: announcement, actor: @tenant_admin)

    payload = Notifications::PushPayload.build(announcement.notifications.first)

    assert_equal "Corte de agua", payload[:title]
    assert payload[:body].length <= Notifications::AnnouncementPushPayload::BODY_LIMIT
    assert_equal "announcement", payload[:data][:type]
    assert_equal announcement.id, payload[:data][:announcement_id]
  end

  test "property admin publishes on their property only" do
    Announcements::Publish.call(announcement: create_announcement, actor: @property_admin)

    assert_raises(Pundit::NotAuthorizedError) do
      Announcements::Publish.call(announcement: create_announcement(property: @property_q), actor: @property_admin)
    end
  end

  test "concierge and residents cannot publish" do
    [ @concierge, @picker ].each do |actor|
      assert_raises(Pundit::NotAuthorizedError) do
        Announcements::Publish.call(announcement: create_announcement, actor: actor)
      end
    end
  end

  test "an already published announcement is not published again" do
    announcement = create_announcement(status: AnnouncementStatuses::PUBLISHED)

    assert_no_enqueued_jobs only: DeliverPushNotificationJob do
      assert_raises(Pundit::NotAuthorizedError) do
        Announcements::Publish.call(announcement: announcement, actor: @tenant_admin)
      end
    end
  end

  test "archive withdraws a published announcement" do
    announcement = create_announcement(status: AnnouncementStatuses::PUBLISHED)

    Announcements::Archive.call(announcement: announcement, actor: @tenant_admin)

    assert_equal AnnouncementStatuses::ARCHIVED, announcement.reload.status
  end
end
