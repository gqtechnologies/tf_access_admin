# frozen_string_literal: true

module Notifications
  # Push for the host when the concierge turned someone away because they did
  # not match the invited visitor. Localized in the recipient's language; the
  # data payload carries the same navigation keys as visit_request.
  class VisitEntryDeniedPushPayload
    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @visit = notification.notifiable
    end

    def build
      visitor_name = @visit.visitor_person&.display_name

      I18n.with_locale(recipient_locale) do
        {
          title: I18n.t("notifications.visit_entry_denied.title"),
          body: I18n.t("notifications.visit_entry_denied.body", visitor_name: visitor_name),
          data: {
            type: NotificationTypes::VISIT_ENTRY_DENIED,
            visit_id: @visit.id,
            unit_id: @visit.unit_id,
            residential_property_id: @visit.residential_property_id,
            visitor_name: visitor_name
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
