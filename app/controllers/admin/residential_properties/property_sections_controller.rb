# frozen_string_literal: true

# Canonical channel for property-section mutations (improve-property-sections §7.1).
# Every action loads tenant-safe records through policy scopes (§7.4), authorizes
# with property context, and delegates the work to a domain service (§7.2). The
# organization/property are taken from the nested route, never from client params
# (§7.8). Archive replaces destructive deletion (§7.5).
class Admin::ResidentialProperties::PropertySectionsController < AdminController
  include RespondsToSectionResult

  before_action :set_residential_property
  before_action :set_property_section, only: %i[update move archive]

  def create
    section = @residential_property.property_sections.new
    authorize section, :create?

    result = PropertySections::Create.call(
      actor: current_user,
      property: @residential_property,
      attributes: section_params
    )
    respond_to_section_result(result, success_path: structure_path, error_path: structure_path)
  end

  def update
    authorize @property_section, :update?

    result = PropertySections::Update.call(
      actor: current_user,
      section: @property_section,
      attributes: section_params
    )
    respond_to_section_result(result, success_path: structure_path, error_path: structure_path)
  end

  def move
    authorize @property_section, :move?

    result = PropertySections::Move.call(
      actor: current_user,
      section: @property_section,
      parent_id: move_params.fetch(:parent_id, PropertySections::Base::PARENT_UNCHANGED),
      position: move_params[:position]
    )
    respond_to_section_result(result, success_path: structure_path, error_path: structure_path)
  end

  def archive
    authorize @property_section, :archive?

    result = PropertySections::Archive.call(
      actor: current_user,
      section: @property_section
    )
    respond_to_section_result(result, success_path: structure_path, error_path: structure_path)
  end

  private

  # §7.8: descriptive attributes only; organization/property never come from the
  # client. Lifecycle/parent changes are mediated by their dedicated services.
  def section_params
    params.require(:property_section).permit(
      :name, :section_type, :position, :parent_id, :status, metadata: {}
    )
  end

  def move_params
    params.require(:property_section).permit(:parent_id, :position)
  end

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: { base: [ I18n.t("frontend.admin.residential_properties.not_found") ] } }
  end

  # §7.4: section is loaded through the policy scope, restricted to the property.
  def set_property_section
    @property_section = policy_scope(PropertySection)
      .where(residential_property: @residential_property)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to structure_path,
                inertia: { errors: { base: [ I18n.t("frontend.admin.property_sections.not_found") ] } }
  end

  def structure_path
    admin_residential_property_structure_path(@residential_property)
  end
end
