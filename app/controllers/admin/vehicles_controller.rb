# frozen_string_literal: true

# The administration's register of a property's vehicles (what residents
# registered), searchable by plate, with the option to remove one.
class Admin::VehiclesController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_OCCUPANCIES

  def index
    authorize AuthorizedResident, :index?

    property = active_managed_property(CAPABILITY)
    vehicles = property ? vehicles_of(property) : Vehicle.none
    plate = Vehicle.normalize_plate(params.dig(:q, :query))
    vehicles = vehicles.where("vehicles.metadata->>'plate_number' LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(plate)}%") if plate
    vehicles = vehicles.includes(:unit, :person).order("units.identifier").page(@filters[:page]).per(@filters[:per_page])

    render inertia: "admin/vehicles/index", props: {
      vehicles: vehicles.map { |vehicle| serialize(vehicle) },
      pagination: pagination_info(vehicles),
      query: params.dig(:q, :query),
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property)
    }
  end

  def destroy
    vehicle = Vehicle.joins(:unit).where(units: { residential_property_id: managed_properties_for(CAPABILITY).map(&:id) }).find(params[:id])
    vehicle.destroy!

    redirect_to admin_vehicles_path(property_id: vehicle.unit.residential_property_id)
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_vehicles_path, inertia: { errors: { base: [ t("frontend.admin.vehicles.errors.not_found") ] } }
  end

  private

  def vehicles_of(property)
    Vehicle.active.joins(:unit).where(units: { residential_property_id: property.id })
  end

  def serialize(vehicle)
    {
      id: vehicle.id,
      plate_number: vehicle.plate_number,
      vehicle_type: vehicle.vehicle_type,
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      unit: vehicle.unit && (vehicle.unit.display_name.presence || vehicle.unit.identifier),
      owner_name: vehicle.person&.display_name,
      created_at: vehicle.created_at
    }
  end
end
