# frozen_string_literal: true

class Admin::PropertySectionsController < AdminController
  before_action :get_property_section, only: [ :edit, :update, :destroy ]

  def index
    authorize PropertySection
    @q = policy_scope(PropertySection).ransack(params[:q])
    property_sections = @q.result(distinct: true)
      .includes(:residential_property, :parent)
      .order(created_at: :desc)
      .page(@filters[:page])
      .per(@filters[:per_page])

    pagination = pagination_info(property_sections)
    render inertia: "admin/property_sections/index", props: {
      property_sections: property_sections.map { |s| Admin::PropertySectionSerializer.new(s).as_json },
      pagination: pagination
    }, status: :ok
  end

  def edit
    authorize @property_section

    redirect_to "#{admin_residential_property_structure_path(@property_section.residential_property)}?edit=#{@property_section.id}"
  end

  def update
    authorize @property_section

    unless @property_section.update(property_section_params)
      redirect_to edit_admin_property_section_path(@property_section), inertia: { errors: @property_section.errors }
    else
      redirect_to admin_residential_property_structure_path(@property_section.residential_property)
    end
  end

  def destroy
    authorize @property_section
    @property_section.destroy
    redirect_to admin_property_sections_path
  end

  private

  def property_section_params
    params.require(:property_section).permit(
      :name, :code, :section_type, :position, :parent_id
    )
  end

  def get_property_section
    @property_section = policy_scope(PropertySection).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_property_sections_path, inertia: { errors: [ I18n.t("frontend.admin.property_sections.not_found") ] }
  end

end
