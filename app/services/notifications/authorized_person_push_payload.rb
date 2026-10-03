# frozen_string_literal: true

module Notifications
  # Push for the resident who proposed an authorized person when the
  # administration approves, rejects or revokes them.
  class AuthorizedPersonPushPayload
    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @record = notification.notifiable
    end

    def build
      status = @notification.metadata["authorized_status"].presence || @record.status
      name = @record.person&.display_name
      unit = @record.unit
      unit_name = unit.display_name.presence || unit.identifier

      I18n.with_locale(recipient_locale) do
        {
          title: I18n.t("notifications.authorized_person.#{status}.title", default: I18n.t("notifications.authorized_person.updated.title")),
          body: I18n.t("notifications.authorized_person.#{status}.body", name: name, unit: unit_name,
                       default: I18n.t("notifications.authorized_person.updated.body", name: name, unit: unit_name)),
          data: {
            type: NotificationTypes::AUTHORIZED_PERSON,
            authorized_person_id: @record.id,
            status: status,
            unit_id: unit.id,
            unit_name: unit_name,
            residential_property_id: unit.residential_property_id
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
