# frozen_string_literal: true

# Parcel payload shared by the resident listing (GET /units/:unit_id/parcels)
# and the concierge endpoints (/concierge/parcels).
class Api::Private::ParcelSerializer < ActiveModel::Serializer
  attributes :id, :delivery_type, :courier_company, :tracking_code, :notes, :status,
             :received_at, :withdrawn_at, :withdrawn_by_name, :unit

  def withdrawn_by_name
    object.withdrawn_by_person&.display_name
  end

  def unit
    { id: object.unit.id, name: object.unit.display_name.presence || object.unit.identifier }
  end
end
