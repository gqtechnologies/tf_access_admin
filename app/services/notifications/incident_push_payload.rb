# frozen_string_literal: true

module Notifications
  # Push for whoever reported an incident when the administration changes its
  # status. The status is read from the notification so an old push keeps
  # saying what it said.
  class IncidentPushPayload
    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @incident = notification.notifiable
    end

    def build
      status = @notification.metadata["incident_status"].presence || @incident.status

      I18n.with_locale(recipient_locale) do
        category = I18n.t("notifications.incident.categories.#{@incident.category}", default: @incident.category)
        {
          title: I18n.t("notifications.incident.#{status}.title", default: I18n.t("notifications.incident.updated.title")),
          body: I18n.t("notifications.incident.#{status}.body", default: I18n.t("notifications.incident.updated.body", category: category),
                       category: category, resolution: @incident.resolution.to_s).strip,
          data: {
            type: NotificationTypes::INCIDENT,
            incident_id: @incident.id,
            status: status,
            residential_property_id: @incident.residential_property_id
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
