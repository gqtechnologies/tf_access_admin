# frozen_string_literal: true

# An incident as its reporter sees it through the private API.
class Api::Private::IncidentSerializer < ActiveModel::Serializer
  attributes :id, :category, :description, :priority, :status, :resolution,
             :created_at, :resolved_at, :residential_property, :unit, :common_area

  def residential_property
    { id: object.residential_property_id, name: object.residential_property.name }
  end

  def unit
    object.unit && { id: object.unit_id, name: object.unit.display_name.presence || object.unit.identifier }
  end

  def common_area
    object.common_area && { id: object.common_area_id, name: object.common_area.name }
  end
end
