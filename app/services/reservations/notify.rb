# frozen_string_literal: true

module Reservations
  # Pushes the reservation's current outcome (approved, rejected, cancelled by
  # the administration) to the resident who asked for it. Never raises.
  class Notify
    def self.call(reservation:)
      notification = Notification.create!(
        organization: reservation.organization,
        recipient_person: reservation.requested_by_person,
        unit: reservation.unit,
        residential_property: reservation.residential_property,
        notifiable: reservation,
        notification_type: NotificationTypes::RESERVATION,
        channel: NotificationChannels::PUSH,
        status: NotificationStatuses::PENDING,
        metadata: { "reservation_status" => reservation.status }
      )
      DeliverPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.error("[Reservations::Notify] reservation=#{reservation.id} #{e.class}: #{e.message}")
    end
  end
end
