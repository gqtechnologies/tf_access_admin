# frozen_string_literal: true

module Announcements
  # Publishes a draft and pushes it to every person with a currently valid
  # occupancy or ownership in the announcement's property, once per person.
  class Publish
    include Authorization::ActorContext

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(announcement:, actor:)
      @announcement = announcement
      @actor = actor
    end

    def call
      with_actor_context do
        raise Pundit::NotAuthorizedError unless AnnouncementPolicy.new(@actor, @announcement).publish?
      end

      @announcement.with_lock do
        raise Pundit::NotAuthorizedError unless @announcement.draft?

        @announcement.update!(status: AnnouncementStatuses::PUBLISHED, published_at: Time.zone.now)
      end

      # Outside the lock: a notification failure never undoes the publication.
      notify_residents
      @announcement
    end

    private

    def notify_residents
      Person.where(id: Authorization::ActiveRelationships.active_person_ids_of_property(@announcement.residential_property))
            .find_each do |person|
        notification = Notification.create!(
          organization: @announcement.organization,
          recipient_person: person,
          residential_property: @announcement.residential_property,
          notifiable: @announcement,
          notification_type: NotificationTypes::ANNOUNCEMENT,
          channel: NotificationChannels::PUSH,
          status: NotificationStatuses::PENDING
        )
        DeliverPushNotificationJob.perform_later(notification.id)
      end
    rescue StandardError => e
      Rails.logger.error("[Announcements::Publish] announcement=#{@announcement.id} #{e.class}: #{e.message}")
    end
  end
end
