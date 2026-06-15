# frozen_string_literal: true

class Admin::UnitSerializer < ActiveModel::Serializer
  attributes :id,
    :identifier,
    :display_name,
    :title,
    :unit_type,
    :status,
    :area_m2,
    :residential_property_id,
    :residential_property_name,
    :property_section_id,
    :location_path,
    :ownership_stats,
    :occupancy_stats

  def title
    return object.display_name if object.display_name.present?

    I18n.t("frontend.admin.units.show.unit_title", identifier: object.identifier)
  end

  def residential_property_name
    instance_options[:residential_property_name] || object.residential_property&.name
  end

  def location_path
    instance_options[:location_path] || []
  end

  def ownership_stats
    instance_options[:ownership_stats] || Unit::OwnershipStats.for(object)
  end

  def occupancy_stats
    instance_options[:occupancy_stats] || Unit::OccupancyStats.for(object)
  end
end
