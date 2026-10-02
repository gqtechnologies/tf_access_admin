# frozen_string_literal: true

module Notifications
  # Push for the residents of a unit when a parcel arrives at the front desk.
  class ParcelPushPayload
    def self.build(notification)
      new(notification).build
    end

    def initialize(notification)
      @notification = notification
      @parcel = notification.notifiable
    end

    def build
      unit = @parcel.unit
      unit_name = unit.display_name.presence || unit.identifier

      I18n.with_locale(recipient_locale) do
        {
          title: I18n.t("notifications.parcel.title"),
          body: I18n.t(
            "notifications.parcel.body",
            delivery_type: I18n.t("notifications.parcel.delivery_types.#{@parcel.delivery_type}"),
            unit: unit_name
          ),
          data: {
            type: NotificationTypes::PARCEL,
            parcel_id: @parcel.id,
            unit_id: @parcel.unit_id,
            unit_name: unit_name,
            residential_property_id: @parcel.residential_property_id
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
