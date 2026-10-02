# frozen_string_literal: true

module Parcels
  # Registers that a resident with the withdrawal permission picked a parcel up.
  class Withdraw
    include ServiceAuthorization

    class NotWaitingError < StandardError; end
    class NotEligibleError < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(parcel:, actor:, person_id:)
      @parcel = parcel
      @actor = actor
      @person_id = person_id.to_s.presence
    end

    def call
      authorize_parcel_action!(@parcel, :withdraw?)

      person = actor_person
      # with_lock: two front-desk requests for the same parcel queue on the row;
      # the second one finds it withdrawn after the reload.
      @parcel.with_lock do
        raise NotWaitingError unless @parcel.waiting?
        raise NotEligibleError unless EligibleWithdrawers.include?(unit: @parcel.unit, person_id: @person_id)

        @parcel.update!(
          status: ParcelStatuses::WITHDRAWN,
          withdrawn_at: Time.zone.now,
          withdrawn_by_person_id: @person_id
        )
        @parcel.parcel_delivery_status_histories.create!(
          organization: @parcel.organization,
          from_status: ParcelStatuses::RECEIVED,
          to_status: ParcelStatuses::WITHDRAWN,
          changed_by_person: person
        )
      end

      @parcel
    end
  end
end
