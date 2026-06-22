# frozen_string_literal: true

class Admin::ResidentialPropertiesController < AdminController
  include RespondsToPropertyResult

  before_action :get_residential_property, only: %i[edit update archive]

  def index
    authorize ResidentialProperty
    @q = policy_scope(ResidentialProperty).ransack(params[:q])
    residential_properties = @q.result(distinct: true)
      .order(created_at: :desc)
      .page(@filters[:page])
      .per(@filters[:per_page])

    pagination = pagination_info(residential_properties)
    render inertia: "admin/residential_properties/index", props: {
      residential_properties: serialize_properties(residential_properties),
      pagination: pagination
    }, status: :ok
  end

  def new
    authorize ResidentialProperty
    render inertia: "admin/residential_properties/new", props: {
      residential_property: serialize_property(ResidentialProperty.new),
      property_types: PropertyTypes::ALL
    }, status: :ok
  end

  def create
    authorize ResidentialProperty

    result = Properties::Create.call(
      actor: current_user,
      attributes: residential_property_params
    )
    respond_to_property_result(
      result,
      success_path: admin_residential_properties_path,
      error_path: new_admin_residential_property_path
    )
  end

  def edit
    authorize @residential_property

    render inertia: "admin/residential_properties/edit", props: {
      residential_property: serialize_property(@residential_property),
      property_types: PropertyTypes::ALL
    }, status: :ok
  end

  def update
    authorize @residential_property

    result = Properties::Update.call(
      actor: current_user,
      property: @residential_property,
      attributes: residential_property_params
    )
    respond_to_property_result(
      result,
      success_path: edit_admin_residential_property_path(@residential_property),
      error_path: edit_admin_residential_property_path(@residential_property)
    )
  end

  def archive
    authorize @residential_property, :archive?

    result = Properties::Archive.call(
      actor: current_user,
      property: @residential_property
    )
    respond_to_property_result(
      result,
      success_path: admin_residential_properties_path,
      error_path: admin_residential_properties_path
    )
  end

  private

  def residential_property_params
    params.require(:residential_property).permit(
      :name, :code, :property_type, :address_line, :city, :region, :country, :timezone, :status
    )
  end

  def get_residential_property
    @residential_property = policy_scope(ResidentialProperty).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_residential_properties_path,
                inertia: { errors: { base: [ I18n.t("frontend.admin.residential_properties.not_found") ] } }
  end

  def serialize_property(property)
    Admin::ResidentialPropertySerializer.new(property, current_user: current_user).as_json
  end

  def serialize_properties(properties)
    properties.map { |property| serialize_property(property) }
  end
end
