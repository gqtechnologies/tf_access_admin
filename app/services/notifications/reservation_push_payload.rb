# frozen_string_literal: true

module Notifications
  # Push for a resident when the administration decides on (or cancels) their
  # common area reservation. The status is read from the notification, so a
  # later change of the reservation doesn't rewrite what an old push said.
  class ReservationPushPayload
    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @reservation = notification.notifiable
    end

    def build
      status = @notification.metadata["reservation_status"].presence || @reservation.status
      zone = @reservation.common_area.time_zone

      I18n.with_locale(recipient_locale) do
        {
          title: I18n.t("notifications.reservation.#{status}.title", default: I18n.t("notifications.reservation.updated.title")),
          body: I18n.t(
            "notifications.reservation.#{status}.body",
            default: I18n.t("notifications.reservation.updated.body", area: @reservation.common_area.name),
            area: @reservation.common_area.name,
            date: I18n.l(@reservation.starts_at.in_time_zone(zone), format: :short),
            reason: @reservation.rejection_reason.to_s
          ).strip,
          data: {
            type: NotificationTypes::RESERVATION,
            reservation_id: @reservation.id,
            status: status,
            unit_id: @reservation.unit_id,
            unit_name: @reservation.unit.display_name.presence || @reservation.unit.identifier,
            residential_property_id: @reservation.residential_property_id
          }
        }
      end
    end

    private

    def recipient_locale
      @notification.recipient_person&.user&.language.presence || I18n.default_locale
    end
  end
end
