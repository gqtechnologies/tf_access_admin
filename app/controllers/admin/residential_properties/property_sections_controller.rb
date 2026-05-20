# frozen_string_literal: true

class Admin::ResidentialProperties::PropertySectionsController < AdminController
  before_action :set_residential_property
  before_action :set_property_section, only: [ :update, :destroy ]

  def create
    authorize PropertySection

    @property_section = @residential_property.property_sections.build(property_section_params)

    if @property_section.save
      redirect_to admin_residential_property_structure_path(@residential_property)
    else
      redirect_to admin_residential_property_structure_path(@residential_property),
                  inertia: { errors: @property_section.errors }
    end
  end

  def update
    authorize @property_section

    if @property_section.update(property_section_params)
      redirect_to admin_residential_property_structure_path(@residential_property)
    else
      redirect_to admin_residential_property_structure_path(@residential_property),
                  inertia: { errors: @property_section.errors }
    end
  end

  def destroy
    authorize @property_section
    @property_section.destroy
    redirect_to admin_residential_property_structure_path(@residential_property)
  end

  private

  def property_section_params
    params.require(:property_section).permit(:name, :code, :section_type, :position, :parent_id)
  end

  def set_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:residential_property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: [ I18n.t("frontend.admin.residential_properties.not_found") ] }
  end

  def set_property_section
    @property_section = policy_scope(PropertySection)
      .where(residential_property: @residential_property)
      .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_property_structure_path(@residential_property),
                inertia: { errors: [ I18n.t("frontend.admin.property_sections.not_found") ] }
  end
end
