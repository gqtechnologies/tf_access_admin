# frozen_string_literal: true

class Admin::ResidentialProperties::StructuresController < AdminController
  before_action :set_residential_property

  def show
    # The structure DTO exposes sections and units, so access requires
    # +manage_sections+ on this specific property — not generic property access
    # (improve-property-sections §6.1). Authorize through PropertySectionPolicy
    # with explicit property context before building/serializing the tree.
    authorize @residential_property, :show?, policy_class: PropertySectionPolicy

    # §7.6: the property-scoped TreeBuilder owns scoping, ordering, effective
    # status and the backend-driven per-node permissions exposed to the UI.
    tree_builder = PropertySections::TreeBuilder.new(
      actor: current_user,
      property: @residential_property,
      include_units: true
    )

    render inertia: "admin/residential_properties/structure", props: {
      residential_property: Admin::ResidentialPropertySerializer.new(
        @residential_property, current_user: current_user
      ).as_json,
      section_tree: tree_builder.tree,
      parent_options: tree_builder.parent_options,
      structure_permissions: tree_builder.page_permissions,
      section_types: SectionTypes::ALL,
      section_statuses: SectionStatuses::ALL
    }, status: :ok
  end

  private

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: { base: [ I18n.t("frontend.admin.residential_properties.not_found") ] } }
  end
end
