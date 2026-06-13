# frozen_string_literal: true

class Admin::UnitOwnershipSerializer < ActiveModel::Serializer
  attributes :id,
    :ownership_percentage,
    :starts_at,
    :ends_at,
    :status,
    :validity_state,
    :person_id,
    :person_display_name,
    :person_document_type,
    :person_document_number,
    :person_email

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
    today = Date.current
    return "finished" if object.ends_at.present? && object.ends_at < today
    return "pending" if object.starts_at.present? && object.starts_at > today
    return "inactive" if object.status != UnitOwnership::STATUS_ACTIVE

    "current"
  end
end
