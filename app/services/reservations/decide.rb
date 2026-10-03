# frozen_string_literal: true

module Reservations
  # The administration approves or rejects a pending reservation; the resident
  # who asked gets a push either way.
  class Decide
    include Authorization::ActorContext

    class NotPending < StandardError; end

    DECISIONS = {
      approve: ReservationStatuses::APPROVED,
      reject: ReservationStatuses::REJECTED
    }.freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(reservation:, actor:, decision:, reason: nil)
      @reservation = reservation
      @actor = actor
      @to_status = DECISIONS.fetch(decision.to_sym)
      @reason = reason.to_s.strip.presence
    end

    def call
      with_actor_context do
        raise Pundit::NotAuthorizedError unless CommonAreaPolicy.new(@actor, @reservation.common_area).decide?
      end

      person = @actor.person_for(ActsAsTenant.current_tenant)

      @reservation.with_lock do
        raise NotPending unless @reservation.pending?

        attributes = { status: @to_status }
        if @to_status == ReservationStatuses::APPROVED
          attributes.merge!(approved_at: Time.zone.now, approved_by_person: person)
        else
          attributes[:rejection_reason] = @reason
        end
        @reservation.update!(attributes)

        @reservation.common_area_reservation_status_histories.create!(
          organization: @reservation.organization,
          from_status: ReservationStatuses::PENDING,
          to_status: @to_status,
          changed_by_person: person,
          reason: @reason
        )
      end

      Reservations::Notify.call(reservation: @reservation)
      @reservation
    end
  end
end
