# frozen_string_literal: true

# An authorized person of a unit, as residents and the front desk see it.
# The document is included because the front desk verifies it at the door.
class Api::Private::AuthorizedPersonSerializer < ActiveModel::Serializer
  attributes :id, :name, :document, :relationship_type, :status, :starts_at, :ends_at,
             :can_withdraw_parcels, :unit, :avatar_url

  def name
    object.person&.display_name
  end

  def document
    object.person&.document_number
  end

  def unit
    { id: object.unit_id, name: object.unit.display_name.presence || object.unit.identifier }
  end

  def avatar_url
    object.person&.user&.avatar_path
  end
end
