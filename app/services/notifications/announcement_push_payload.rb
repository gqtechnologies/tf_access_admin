# frozen_string_literal: true

module Notifications
  # Push for the residents of a property when the administration publishes an announcement.
  class AnnouncementPushPayload
    BODY_LIMIT = 140

    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @announcement = notification.notifiable
    end

    def build
      {
        title: @announcement.title,
        body: @announcement.content.to_s.squish.truncate(BODY_LIMIT),
        data: {
          type: NotificationTypes::ANNOUNCEMENT,
          announcement_id: @announcement.id,
          residential_property_id: @announcement.residential_property_id
        }
      }
    end
  end
end
