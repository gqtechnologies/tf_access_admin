# frozen_string_literal: true

class Admin::ResidentialProperties::UnitsController < AdminController
  before_action :set_residential_property
  before_action :set_unit
  before_action :set_filters, only: [ :show ]

  def show
    authorize @unit

    sections = policy_scope(PropertySection)
      .where(residential_property: @residential_property)
      .to_a
    sections_by_id = sections.index_by(&:id)

    location_path = if @unit.property_section_id.present?
      section = sections_by_id[@unit.property_section_id]
      PropertySection::BreadcrumbPath.build(section, sections_by_id: sections_by_id)
    else
      []
    end

    ownerships = @unit.unit_ownerships
      .includes(:person)
      .ordered_for_display
      .page(@filters[:page])
      .per(@filters[:per_page])

    ownership_stats = Unit::OwnershipStats.for(@unit)

    occupancies_scope = @unit.unit_occupancies
      .includes(:person)
      .ordered_for_display
    occupancies_scope = occupancies_scope.where(status: OccupancyStatuses::ACTIVE) unless occupancies_filters[:include_inactive]
    occupancies = occupancies_scope
      .page(occupancies_filters[:page])
      .per(occupancies_filters[:per_page])

    occupancy_stats = Unit::OccupancyStats.for(@unit)

    render inertia: "admin/units/show", props: {
      unit: Admin::UnitSerializer.new(
        @unit,
        residential_property_name: @residential_property.name,
        location_path: location_path,
        ownership_stats: ownership_stats,
        occupancy_stats: occupancy_stats
      ).as_json,
      ownerships: ownerships.map { |ownership| Admin::UnitOwnershipSerializer.new(ownership).as_json },
      ownerships_pagination: pagination_info(ownerships),
      occupancies: occupancies.map { |occupancy| Admin::UnitOccupancySerializer.new(occupancy).as_json },
      occupancies_pagination: pagination_info(occupancies, per_page: occupancies_filters[:per_page]),
      occupancy_types: occupancy_type_options,
      occupancy_permissions: occupancy_permissions,
      occupancies_include_inactive: occupancies_filters[:include_inactive],
      change_history: Unit::ChangeHistory.for(@unit)
    }, status: :ok
  end

  private

  def occupancies_filters
    @occupancies_filters ||= {
      page: params[:occupancies_page] || params[:page] || 1,
      per_page: params[:occupancies_per_page] || params[:per_page] || 10,
      include_inactive: ActiveModel::Type::Boolean.new.cast(params[:occupancies_include_inactive]) == true
    }
  end

  def occupancy_type_options
    OccupancyTypes::ALL.map do |type|
      {
        value: type,
        label: I18n.t("frontend.admin.unit_occupancies.occupancy_types.#{type}")
      }
    end
  end

  def occupancy_permissions
    {
      create: policy(UnitOccupancy).create?,
      update: policy(UnitOccupancy).update?,
      destroy: policy(UnitOccupancy).destroy?
    }
  end

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: [ I18n.t("frontend.admin.residential_properties.not_found") ] }
  end

  def set_unit
    @unit = policy_scope(Unit)
      .where(residential_property: @residential_property)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_property_structure_path(@residential_property),
                inertia: { errors: [ I18n.t("frontend.admin.units.not_found") ] }
  end
end
