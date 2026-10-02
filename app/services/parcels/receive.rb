# frozen_string_literal: true

module Parcels
  # Registers a parcel that arrived at the front desk for a unit and tells the
  # unit's residents. See openspec/changes/2026-10-02-parcel-deliveries.
  class Receive
    include ServiceAuthorization

    PERMITTED = %i[delivery_type courier_company tracking_code notes].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, actor:, attributes: {})
      @unit = unit
      @actor = actor
      @attributes = attributes.to_h.symbolize_keys.slice(*PERMITTED)
    end

    # Returns the persisted ParcelDelivery; raises ActiveRecord::RecordInvalid
    # on bad attributes and Pundit::NotAuthorizedError without manage_parcels.
    def call
      parcel = ParcelDelivery.new(
        organization: @unit.organization,
        residential_property: @unit.residential_property,
        unit: @unit,
        status: ParcelStatuses::RECEIVED,
        received_at: Time.zone.now,
        **@attributes
      )
      parcel.delivery_type = DeliveryTypes::PARCEL if parcel.delivery_type.blank?

      authorize_parcel_action!(parcel, :create?)

      person = actor_person
      ActiveRecord::Base.transaction do
        parcel.received_by_person = person
        parcel.save!
        parcel.parcel_delivery_status_histories.create!(
          organization: parcel.organization,
          from_status: nil,
          to_status: ParcelStatuses::RECEIVED,
          changed_by_person: person
        )
      end

      # Outside the transaction: a notification failure never undoes the arrival.
      NotifyResidents.call(parcel: parcel)

      parcel
    end
  end
end
