# frozen_string_literal: true

# A vehicle as residents and the front desk see it.
class Api::Private::VehicleSerializer < ActiveModel::Serializer
  attributes :id, :plate_number, :vehicle_type, :brand, :model, :color, :unit, :owner_name

  def unit
    object.unit && { id: object.unit_id, name: object.unit.display_name.presence || object.unit.identifier }
  end

  def owner_name
    object.person&.display_name
  end
end
