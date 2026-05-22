# frozen_string_literal: true

class Admin::ResidentialProperties::BulkImportsController < AdminController
  before_action :set_residential_property
  before_action :set_property_section, only: :create
  before_action :set_bulk_import, only: :update

  def create
    authorize BulkImport

    bulk_import = BulkImportServices::CreateUnitsImport.call(
      residential_property: @residential_property,
      property_section: @property_section,
      created_by: current_user,
      file: bulk_import_params.require(:file)
    )

    render_bulk_import(bulk_import, status: :created)
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
  end

  def update
    authorize @bulk_import

    bulk_import = BulkImportServices::UpdateUnitsImport.call(
      bulk_import: @bulk_import,
      file: bulk_import_update_params[:file],
      selected_sheet: bulk_import_update_params[:selected_sheet],
      options: options_from_update_params
    )

    render_bulk_import(bulk_import)
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
  end

  private

  def bulk_import_params
    params.require(:bulk_import).permit(:file, :property_section_id, :import_type)
  end

  def bulk_import_update_params
    params.require(:bulk_import).permit(
      :file,
      :selected_sheet,
      :import_mode,
      :default_property_section_id,
      :validate_owners,
    )
  end

  def options_from_update_params
    permitted = bulk_import_update_params
    options = permitted.slice(:import_mode, :default_property_section_id, :validate_owners)
    options[:validate_owners] = ActiveModel::Type::Boolean.new.cast(options[:validate_owners]) if options.key?(:validate_owners)
    options.compact
  end

  def render_bulk_import(bulk_import, status: :ok)
    render json: {
      bulk_import: Admin::BulkImportSerializer.new(bulk_import).as_json
    }, status: status
  end

  def render_validation_errors(record)
    render json: {
      errors: record.errors.to_hash(true).transform_values { |messages| Array(messages) }
    }, status: :unprocessable_entity
  end

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: { base: [ I18n.t("frontend.admin.residential_properties.not_found") ] } },
           status: :not_found
  end

  def set_property_section
    section_id = bulk_import_params[:property_section_id]
    return render_property_section_required if section_id.blank?

    @property_section = policy_scope(PropertySection)
      .where(residential_property: @residential_property)
      .find(section_id)
  rescue ActiveRecord::RecordNotFound
    render json: { errors: { base: [ I18n.t("frontend.admin.property_sections.not_found") ] } },
           status: :not_found
  end

  def set_bulk_import
    @bulk_import = policy_scope(BulkImport)
      .where(residential_property: @residential_property)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: { base: [ I18n.t("frontend.admin.bulk_imports.not_found") ] } },
           status: :not_found
  end

  def render_property_section_required
    render json: {
      errors: { property_section_id: [ I18n.t("frontend.admin.bulk_imports.property_section_required") ] }
    }, status: :unprocessable_entity
  end
end
