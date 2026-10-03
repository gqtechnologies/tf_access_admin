# frozen_string_literal: true

# GET /api/v1/private/concierge/vehicles?property_id=&plate=
#
# Plate lookup at the gate: the active vehicles of an operated property whose
# plate contains what was typed (ignoring spaces, dashes and case).
class Api::V1::Private::Concierge::VehiclesController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  LIMIT = 20

  before_action :load_property!

  def index
    plate = Vehicle.normalize_plate(params[:plate])
    return render(json: { data: [] }, status: :ok) if plate.blank?

    vehicles = Vehicle.active
                      .joins(:unit)
                      .where(units: { residential_property_id: @property.id })
                      .where("vehicles.metadata->>'plate_number' LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(plate)}%")
                      .includes(:person, :unit)
                      .limit(LIMIT)

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(vehicles, each_serializer: Api::Private::VehicleSerializer).as_json
    }, status: :ok
  end
end
