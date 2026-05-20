# frozen_string_literal: true

class Admin::PropertySectionSerializer < ActiveModel::Serializer
  attributes :id, :name, :code, :section_type, :position, :metadata,
             :organization_id, :residential_property_id, :parent_id,
             :created_at, :updated_at,
             :residential_property_name, :parent_name

  def residential_property_name
    object.residential_property&.name
  end

  def parent_name
    object.parent&.name
  end
end
