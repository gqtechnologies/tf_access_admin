# frozen_string_literal: true

module Visits
  # The concierge found that the person at the door is not the invited visitor.
  # The visit stays authorized (the right person may still arrive), the attempt
  # is recorded in the history, and only the host is notified.
  # See openspec/changes/2026-09-21-concierge-identity-check/design.md D3.
  class DenyEntry
    include ServiceAuthorization

    COOLDOWN = 5.minutes
    METADATA_KEY = "entry_denied_at"

    class NotDeniableError < StandardError; end

    class CooldownError < StandardError
      attr_reader :retry_after

      def initialize(retry_after)
        @retry_after = retry_after
        super("entry denied too recently")
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(visit:, actor:)
      @visit = visit
      @actor = actor
    end

    def call
      # Whoever may let the visitor in may also turn them away.
      authorize_visit_action!(@visit, :check_in?)
      raise NotDeniableError unless @visit.status == VisitStatuses::AUTHORIZED

      remaining = cooldown_remaining
      raise CooldownError, remaining if remaining.positive?

      ActiveRecord::Base.transaction do
        # update_column: Visit.sanitize_metadata drops non-operational root keys
        # on validated saves (same approach as ResendVisitorInvitation).
        metadata = (@visit.metadata || {}).merge(METADATA_KEY => Time.zone.now.iso8601)
        @visit.update_column(:metadata, metadata) # rubocop:disable Rails/SkipsModelValidations

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::ENTRY_DENIED,
          from_status: @visit.status,
          to_status: @visit.status,
          actor: @actor
        )
      end

      notify_host

      @visit
    end

    private

    def cooldown_remaining
      raw = (@visit.metadata || {})[METADATA_KEY]
      last = raw.present? ? Time.zone.parse(raw.to_s) : nil
      return 0 if last.nil?

      [ (last + COOLDOWN - Time.zone.now).ceil, 0 ].max
    rescue ArgumentError
      0
    end

    # Only the host — whoever authorized the visit, else whoever created it —
    # never the unit's other residents. A failure here must not undo the record.
    def notify_host
      host = @visit.authorized_by || @visit.created_by
      person = host&.person_for(@visit.organization)
      return if person.blank?

      notification = Notification.create!(
        organization: @visit.organization,
        recipient_person: person,
        unit: @visit.unit,
        residential_property: @visit.residential_property,
        notifiable: @visit,
        notification_type: NotificationTypes::VISIT_ENTRY_DENIED,
        channel: NotificationChannels::PUSH,
        status: NotificationStatuses::PENDING
      )
      DeliverPushNotificationJob.perform_later(notification.id)
    rescue StandardError => e
      Rails.logger.error("[Visits::DenyEntry] visit=#{@visit.id} #{e.class}: #{e.message}")
    end
  end
end
