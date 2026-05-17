# frozen_string_literal: true

class Admin::ResidentialPropertiesController < AdminController
  before_action :set_residential_property, only: [ :create ]
  before_action :get_residential_property, only: [ :edit, :update, :destroy ]

  def index
    authorize ResidentialProperty
    @q = policy_scope(ResidentialProperty).ransack(params[:q])
    residential_properties = @q.result(distinct: true)
      .order(created_at: :desc)
      .page(@filters[:page])
      .per(@filters[:per_page])

    pagination = pagination_info(residential_properties)
    render inertia: "admin/residential_properties/index", props: {
      residential_properties: residential_properties.map { |p| Admin::ResidentialPropertySerializer.new(p).as_json },
      pagination: pagination
    }, status: :ok
  end

  def new
    authorize ResidentialProperty
    render inertia: "admin/residential_properties/new", props: {
      residential_property: Admin::ResidentialPropertySerializer.new(ResidentialProperty.new).as_json,
      property_types: PropertyTypes::ALL
    }, status: :ok
  end

  def create
    authorize ResidentialProperty

    unless @residential_property.save
      redirect_to new_admin_residential_property_path, inertia: { errors: @residential_property.errors }
    else
      redirect_to admin_residential_properties_path
    end
  end

  def edit
    authorize @residential_property

    render inertia: "admin/residential_properties/edit", props: {
      residential_property: Admin::ResidentialPropertySerializer.new(@residential_property).as_json,
      property_types: PropertyTypes::ALL
    }, status: :ok
  end

  def update
    authorize @residential_property

    unless @residential_property.update(residential_property_params)
      redirect_to edit_admin_residential_property_path(@residential_property), inertia: { errors: @residential_property.errors }
    else
      redirect_to edit_admin_residential_property_path(@residential_property)
    end
  end

  def destroy
    authorize @residential_property
    @residential_property.destroy
    redirect_to admin_residential_properties_path
  end

  private

  def residential_property_params
    params.require(:residential_property).permit(
      :name, :code, :property_type, :address_line, :city, :region, :country, :timezone, :status
    )
  end

  def set_residential_property
    @residential_property = ResidentialProperty.new(residential_property_params)
  end

  def get_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path, inertia: { errors: [ I18n.t("frontend.admin.residential_properties.not_found") ] }
  end
end
