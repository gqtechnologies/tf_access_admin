# frozen_string_literal: true

module Notifications
  # Single place that knows which payload builder renders a notification, for
  # both the push delivery job and the in-app inbox.
  #
  # visit_invitation targets the visitor (D4), visit_entry_denied the host,
  # parcel the unit's residents and announcement the property's residents;
  # every other type keeps the resident-facing visit request payload.
  module PushPayload
    BUILDERS = {
      NotificationTypes::VISIT_INVITATION => "Notifications::VisitInvitationPushPayload",
      NotificationTypes::VISIT_ENTRY_DENIED => "Notifications::VisitEntryDeniedPushPayload",
      NotificationTypes::PARCEL => "Notifications::ParcelPushPayload",
      NotificationTypes::ANNOUNCEMENT => "Notifications::AnnouncementPushPayload",
      NotificationTypes::RESERVATION => "Notifications::ReservationPushPayload",
      NotificationTypes::INCIDENT => "Notifications::IncidentPushPayload",
      NotificationTypes::AUTHORIZED_PERSON => "Notifications::AuthorizedPersonPushPayload"
    }.freeze

    def self.build(notification)
      BUILDERS.fetch(notification.notification_type, "Notifications::VisitRequestPushPayload")
              .constantize
              .build(notification)
    end
  end
end
