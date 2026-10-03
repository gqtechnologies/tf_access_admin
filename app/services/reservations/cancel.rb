# frozen_string_literal: true

module Reservations
  # Frees the slot of a pending or approved reservation that has not started.
  # The resident who asked for it may cancel it, and so may the administration
  # (which also tells the resident).
  class Cancel
    include Authorization::ActorContext

    class NotCancellable < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(reservation:, actor:, reason: nil)
      @reservation = reservation
      @actor = actor
      @reason = reason.to_s.strip.presence
    end

    def call
      person = @actor.person_for(ActsAsTenant.current_tenant)
      by_requester = person.present? && person.id == @reservation.requested_by_person_id
      by_manager = !by_requester && manager?
      raise Pundit::NotAuthorizedError unless by_requester || by_manager

      @reservation.with_lock do
        raise NotCancellable unless @reservation.holds_slot? && @reservation.starts_at > Time.zone.now

        from = @reservation.status
        @reservation.update!(status: ReservationStatuses::CANCELLED)
        @reservation.common_area_reservation_status_histories.create!(
          organization: @reservation.organization,
          from_status: from,
          to_status: ReservationStatuses::CANCELLED,
          changed_by_person: person,
          reason: @reason
        )
      end

      Reservations::Notify.call(reservation: @reservation) if by_manager
      @reservation
    end

    private

    def manager?
      with_actor_context { CommonAreaPolicy.new(@actor, @reservation.common_area).decide? }
    end
  end
end
