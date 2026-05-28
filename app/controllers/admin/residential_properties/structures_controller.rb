# frozen_string_literal: true

class Admin::ResidentialProperties::StructuresController < AdminController
  before_action :set_residential_property

  def show
    authorize @residential_property, :show?

    sections = policy_scope(PropertySection)
      .where(residential_property: @residential_property)
      .includes(:units)
      .order(:position, :name)

    tree_builder = PropertySection::TreeBuilder.new(sections)

    render inertia: "admin/residential_properties/structure", props: {
      residential_property: Admin::ResidentialPropertySerializer.new(@residential_property).as_json,
      section_tree: tree_builder.as_json,
      parent_options: tree_builder.root_parent_options,
      section_types: SectionTypes::ALL
    }, status: :ok
  end

  private

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: [ I18n.t("frontend.admin.residential_properties.not_found") ] }
  end
end
