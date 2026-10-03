# frozen_string_literal: true

# A common area reservation as the resident API returns it.
class Api::Private::ReservationSerializer < ActiveModel::Serializer
  attributes :id, :status, :starts_at, :ends_at, :guest_count, :rejection_reason, :common_area, :unit, :can_cancel

  def common_area
    { id: object.common_area_id, name: object.common_area.name, area_type: object.common_area.area_type }
  end

  def unit
    { id: object.unit_id, name: object.unit.display_name.presence || object.unit.identifier }
  end

  # The requester may cancel while it holds the slot and has not started.
  def can_cancel
    viewer = instance_options[:viewer]
    viewer.present? && viewer.id == object.requested_by_person_id &&
      object.holds_slot? && object.starts_at > Time.zone.now
  end
end
