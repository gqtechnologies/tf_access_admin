# frozen_string_literal: true

# Flat, organization-wide section listing. It is a read/navigation surface only:
# mutations live in the canonical nested channel
# (Admin::ResidentialProperties::PropertySectionsController), so this controller
# never duplicates update/archive logic (improve-property-sections §7.3).
class Admin::PropertySectionsController < AdminController
  before_action :get_property_section, only: [ :edit ]

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

  private

  def get_property_section
    @property_section = policy_scope(PropertySection).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_property_sections_path, inertia: { errors: { base: [ I18n.t("frontend.admin.property_sections.not_found") ] } }
  end
end
