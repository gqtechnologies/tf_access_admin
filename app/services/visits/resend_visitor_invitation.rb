# frozen_string_literal: true

module Visits
  # Re-sends the visitor invitation (push + email, via NotifyVisitor) on behalf
  # of a resident. Private-API only: unit-level authorization is enforced by the
  # caller (Residents::VisitContext), not by VisitPolicy.
  #
  # Distinct from ResendNotification, which retries failed pushes to residents.
  # See openspec/changes/2026-09-21-mobile-visit-management/design.md D4.
  class ResendVisitorInvitation
    COOLDOWN = 5.minutes
    METADATA_KEY = "visitor_invitation_resent_at"

    class NotResendableError < StandardError; end

    class CooldownError < StandardError
      attr_reader :retry_after

      def initialize(retry_after)
        @retry_after = retry_after
        super("visitor invitation resent too recently")
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    # State gate only (authorized and not expired) — cooldown excluded.
    def self.state_allows?(visit)
      visit.status == VisitStatuses::AUTHORIZED && !visit.authorization_expired?
    end

    def self.resendable?(visit)
      state_allows?(visit) && cooldown_remaining(visit).zero?
    end

    # Whole seconds left before the next resend is allowed; 0 when none.
    def self.cooldown_remaining(visit)
      raw = (visit.metadata || {})[METADATA_KEY]
      last = raw.present? ? Time.zone.parse(raw.to_s) : nil
      return 0 if last.nil?

      [ (last + COOLDOWN - Time.zone.now).ceil, 0 ].max
    rescue ArgumentError
      0
    end

    def initialize(visit:, actor:)
      @visit = visit
      @actor = actor
    end

    def call
      raise NotResendableError unless self.class.state_allows?(@visit)

      remaining = self.class.cooldown_remaining(@visit)
      raise CooldownError, remaining if remaining.positive?

      # Stamped before notifying: NotifyVisitor swallows delivery failures, and a
      # failed delivery must not enable an immediate retry.
      ActiveRecord::Base.transaction do
        # update_column: Visit.sanitize_metadata drops non-operational root keys on
        # validated saves (same approach as NotifyVisitor's error key).
        metadata = (@visit.metadata || {}).merge(METADATA_KEY => Time.zone.now.iso8601)
        @visit.update_column(:metadata, metadata) # rubocop:disable Rails/SkipsModelValidations

        RecordEvent.call(
          visit: @visit,
          event_type: VisitEventTypes::INVITATION_RESENT,
          from_status: @visit.status,
          to_status: @visit.status,
          actor: @actor
        )
      end

      NotifyVisitor.call(visit: @visit, actor: @actor)

      @visit
    end
  end
end
