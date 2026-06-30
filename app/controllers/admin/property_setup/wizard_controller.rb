# frozen_string_literal: true

class Admin::PropertySetup::WizardController < AdminController
  include RespondsToPropertyResult

  before_action :authorize_setup!
  before_action :set_property, except: %i[new create]

  def new
    render inertia: "admin/property_setup/Wizard", props: wizard_props(step: 1), status: :ok
  end

  def create
    result = Properties::Setup::InitializeDraft.call(
      actor: current_user,
      attributes: step_params
    )

    if result.invalid?
      redirect_to admin_property_setup_new_wizard_path,
                  inertia: { errors: serialize_inertia_errors(result.property) }
    else
      redirect_to admin_property_setup_wizard_path(result.property)
    end
  end

  def show
    render inertia: "admin/property_setup/Wizard", props: wizard_props(step: current_step), status: :ok
  end

  def update
    merge_wizard_state!
    mode = step_params[:structure_mode].presence || Properties::Setup::WizardState.structure_mode(@property) || "none"
    Properties::Setup::WizardState.merge!(@property, structure_mode: mode, quick_structure_confirmed: true) if mode == "quick"
    update_property_descriptive!

    if @property.errors.any?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(@property) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def advance
    merge_wizard_state!
    validation = Properties::Setup::ValidateStep.new(
      property: @property,
      step: current_step,
      attributes: step_params
    ).call

    unless validation[:valid]
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: validation[:errors] }
      return
    end

    apply_step_side_effects!
    Properties::Setup::WizardState.merge!(@property, current_step: [ current_step + 1, 5 ].min)
    @property.save!

    redirect_to admin_property_setup_wizard_path(@property)
  end

  def back
    Properties::Setup::WizardState.merge!(@property, current_step: [ current_step - 1, 1 ].max)
    @property.save!
    redirect_to admin_property_setup_wizard_path(@property)
  end

  def cancel
    result = Properties::Setup::Cancel.call(
      actor: current_user,
      property: @property,
      delete_draft: params[:delete_draft] == true || params[:delete_draft] == "true"
    )

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.property) }
    else
      redirect_to admin_residential_properties_path
    end
  end

  def create_section
    parent = find_parent_section
    result = PropertySections::Create.call(
      actor: current_user,
      property: @property,
      parent: parent,
      attributes: section_params
    )

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.section) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def create_sections
    parent = find_section(batch_section_params[:parent_id])
    result = PropertySections::CreateBatch.call(
      actor: current_user,
      property: @property,
      parent: parent,
      section_type: batch_section_params[:section_type],
      names: batch_names,
      prefix: batch_section_params[:prefix],
      suffix_type: (batch_section_params[:suffix_type].presence || "letter").to_sym,
      count: batch_section_params[:count],
      code: batch_section_params[:code]
    )

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.section) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def update_section
    section = @property.property_sections.find_by(id: params[:section_id])
    return section_not_found if section.nil?

    result = PropertySections::Update.call(
      actor: current_user,
      section: section,
      attributes: section_update_params
    )

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.section) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def destroy_section
    section = @property.property_sections.find_by(id: params[:section_id])
    return section_not_found if section.nil?

    result = PropertySections::Destroy.call(actor: current_user, section: section)

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.section) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def create_unit
    result = Units::Create.call(
      actor: current_user,
      property: @property,
      section_id: unit_params[:property_section_id],
      attributes: unit_params
    )

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.unit) }
    else
      redirect_to admin_property_setup_wizard_path(@property)
    end
  end

  def confirm
    result = Properties::Setup::Confirm.call(actor: current_user, property: @property)

    if result.invalid?
      redirect_to admin_property_setup_wizard_path(@property),
                  inertia: { errors: serialize_inertia_errors(result.property) }
    else
      redirect_to admin_property_setup_wizard_path(result.property, completed: true)
    end
  end

  def structure_preview
    format = Properties::Setup::StructureFormatResolver.for(property_type: @property.property_type)
    preview = Properties::Setup::GenerateStructurePreview.call(
      params: structure_preview_params,
      format: format,
      page: params[:page],
      per_page: params[:per_page]
    )
    render json: preview
  end

  def units_preview
    preview = Properties::Setup::GenerateUnitsPreview.call(
      property: @property,
      params: units_preview_params,
      page: params[:page],
      per_page: params[:per_page]
    )
    render json: preview
  end

  private

  def authorize_setup!
    authorize ResidentialProperty, :create?
  end

  def set_property
    @property = policy_scope(ResidentialProperty).find(params[:id])
    authorize @property, :update?
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: { base: [ I18n.t("frontend.admin.residential_properties.not_found") ] } }
  end

  def current_step
    if params[:completed] == "true"
      5
    else
      Properties::Setup::WizardState.current_step(@property)
    end
  end

  def wizard_props(step:)
    Admin::PropertySetup::WizardSerializer.new(
      property: @property,
      current_user: current_user,
      step: step
    ).as_json.merge(errors: inertia_errors_from_flash)
  end

  def inertia_errors_from_flash
    {}
  end

  def step_params
    params.fetch(:setup, {}).permit(
      :name, :code, :property_type, :address_line, :city, :region, :country, :timezone,
      :estimated_units, :structure_mode, :units_mode, :quick_structure_confirmed,
      quick_structure: %i[
        towers floors_per_tower units_per_floor tower_prefix floor_prefix
        level_1_count level_2_count level_1_prefix level_2_prefix skip_top_level
      ],
      unit_generation: %i[unit_type identifier_format quantity_per_floor units_per_leaf]
    ).to_h
  end

  def structure_preview_params
    params.permit(
      :towers, :floors_per_tower, :units_per_floor, :tower_prefix, :floor_prefix,
      :level_1_count, :level_2_count, :level_1_prefix, :level_2_prefix, :skip_top_level
    )
  end

  def units_preview_params
    params.permit(:unit_type, :identifier_format, :quantity_per_floor)
  end

  def merge_wizard_state!
    Properties::Setup::WizardState.merge!(@property, step_params.slice(
      :structure_mode, :units_mode, :estimated_units, :quick_structure_confirmed
    ))
    Properties::Setup::WizardState.merge!(@property, quick_structure: step_params[:quick_structure]) if step_params[:quick_structure].present?
  end

  def update_property_descriptive!
    attrs = step_params.slice(:name, :code, :property_type, :address_line, :city, :region, :country, :timezone)
    return if attrs.blank?

    @property.assign_attributes(attrs)
    @property.save
  end

  def apply_step_side_effects!
    case current_step
    when 1
      apply_property_step!
    when 2
      apply_structure_step!
    when 3
      apply_units_step!
    end
  end

  def apply_property_step!
    old_type = @property.property_type
    update_property_descriptive!
    return if @property.property_type == old_type

    Properties::Setup::WizardState.merge!(
      @property,
      structure_mode: nil,
      quick_structure_confirmed: nil,
      property_type_changed: true
    )
  end

  def apply_structure_step!
    Properties::Setup::WizardState.merge!(@property, property_type_changed: false)
    mode = step_params[:structure_mode].presence || Properties::Setup::WizardState.structure_mode(@property)
    Properties::Setup::WizardState.merge!(@property, structure_mode: mode)

    return unless mode == "quick" && step_params[:quick_structure].present?

    Properties::Setup::ApplyQuickStructure.call(
      actor: current_user,
      property: @property,
      params: step_params[:quick_structure]
    )
  end

  def apply_units_step!
    mode = step_params[:units_mode].presence || "automatic"
    Properties::Setup::WizardState.merge!(@property, units_mode: mode)

    return if mode == "import"
    return if mode == "individual" && @property.units.any?

    Properties::Setup::ApplyAutomaticUnits.call(
      actor: current_user,
      property: @property,
      count: step_params.dig(:unit_generation, :units_per_leaf)
    ) if mode == "automatic"
  end

  def section_params
    params.require(:property_section).permit(:name, :section_type, :parent_id)
  end

  def batch_section_params
    params.require(:property_section).permit(
      :section_type, :parent_id, :mode, :name, :prefix, :suffix_type, :count, :code
    )
  end

  # Individual mode supplies a single explicit name; multiple mode generates names
  # from prefix/suffix_type/count inside CreateBatch.
  def batch_names
    return [ batch_section_params[:name] ] if batch_section_params[:mode] == "individual"

    nil
  end

  def section_update_params
    params.require(:property_section).permit(:name, :section_type, :code, :status)
  end

  def section_not_found
    redirect_to admin_property_setup_wizard_path(@property),
                inertia: { errors: { base: [ I18n.t("frontend.admin.property_sections.not_found", default: "Section not found") ] } }
  end

  def find_section(section_id)
    return nil if section_id.blank?

    @property.property_sections.find_by(id: section_id)
  end

  def unit_params
    params.require(:unit).permit(:identifier, :display_name, :unit_type, :property_section_id)
  end

  def find_parent_section
    parent_id = section_params[:parent_id]
    return nil if parent_id.blank?

    @property.property_sections.find_by(id: parent_id)
  end
end
