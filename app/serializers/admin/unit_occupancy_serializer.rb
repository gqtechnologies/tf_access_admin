# frozen_string_literal: true

class Admin::UnitOccupancySerializer < ActiveModel::Serializer
  attributes :id,
    :occupancy_type,
    :occupancy_type_label,
    :can_authorize_visits,
    :starts_at,
    :ends_at,
    :status,
    :status_label,
    :validity_state,
    :person_id,
    :person_display_name,
    :person_document_type,
    :person_document_number,
    :person_email

  def occupancy_type_label
    I18n.t(
      "frontend.admin.unit_occupancies.occupancy_types.#{object.occupancy_type}",
      default: object.occupancy_type.to_s.humanize
    )
  end

  def status_label
    I18n.t(
      "frontend.admin.units.show.occupants.statuses.#{object.status}",
      default: object.status.to_s.humanize
    )
  end

  def person_display_name
    object.person&.display_name
  end

  def person_document_type
    object.person&.document_type
  end

  def person_document_number
    object.person&.document_number
  end

  def person_email
    object.person&.contact_email
  end

  def validity_state
    now = Time.zone.now
    day_start = now.beginning_of_day
    day_end = now.end_of_day

    return "finished" if object.ends_at.present? && object.ends_at < day_start
    return "pending" if object.starts_at.present? && object.starts_at > day_end
    return "inactive" if object.status != OccupancyStatuses::ACTIVE

    "current"
  end
end
