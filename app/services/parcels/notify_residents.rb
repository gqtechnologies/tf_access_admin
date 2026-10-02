# frozen_string_literal: true

module Parcels
  # Queues a "parcel" push for every person with a currently valid ownership or
  # occupancy of the parcel's unit — once per person — and stamps notified_at.
  # Never raises: the arrival is already recorded.
  class NotifyResidents
    def self.call(parcel:)
      new(parcel: parcel).call
    end

    def initialize(parcel:)
      @parcel = parcel
    end

    def call
      people = recipients
      return if people.empty?

      people.each do |person|
        notification = Notification.create!(
          organization: @parcel.organization,
          recipient_person: person,
          unit: @parcel.unit,
          residential_property: @parcel.residential_property,
          notifiable: @parcel,
          notification_type: NotificationTypes::PARCEL,
          channel: NotificationChannels::PUSH,
          status: NotificationStatuses::PENDING
        )
        DeliverPushNotificationJob.perform_later(notification.id)
      end

      @parcel.update_column(:notified_at, Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
    rescue StandardError => e
      Rails.logger.error("[Parcels::NotifyResidents] parcel=#{@parcel.id} #{e.class}: #{e.message}")
    end

    private

    def recipients
      relationships = Authorization::ActiveRelationships
      person_ids = relationships.active_occupancies_of_unit(@parcel.unit).pluck(:person_id) |
                   relationships.active_ownerships_of_unit(@parcel.unit).pluck(:person_id)

      Person.where(id: person_ids).to_a
    end
  end
end
