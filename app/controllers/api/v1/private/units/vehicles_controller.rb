# frozen_string_literal: true

# GET    /api/v1/private/units/:unit_id/vehicles
# POST   /api/v1/private/units/:unit_id/vehicles
# DELETE /api/v1/private/units/:unit_id/vehicles/:id
#
# The vehicles of a unit, registered and removed by any person with a currently
# valid occupancy or ownership of it, so the front desk can tell whose car is
# at the gate. A plate is unique within the organization.
class Api::V1::Private::Units::VehiclesController < Api::V1::Private::BaseController
  before_action :load_unit

  def index
    render json: { data: serialize(@unit.vehicles.active.includes(:person, :unit).order(:created_at)), vehicle_types: VehicleTypes::ALL },
           status: :ok
  end

  def create
    vehicle = @unit.vehicles.create!(
      organization: @unit.organization,
      person: person,
      status: Vehicle::STATUS_ACTIVE,
      authorized_from: Time.zone.now,
      **vehicle_params.to_h.symbolize_keys
    )

    render json: { data: serialize(vehicle) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def destroy
    vehicle = @unit.vehicles.find(params[:id])
    vehicle.destroy!

    head :no_content
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def load_unit
    @unit = Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant).find_by(id: params[:unit_id])
    render json: { error: I18n.t("api.vehicles.not_allowed") }, status: :not_found unless @unit
  end

  def serialize(resource)
    options = {}
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::VehicleSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end

  def vehicle_params
    params.require(:vehicle).permit(:plate_number, :vehicle_type, :brand, :model, :color)
  end
end
