# frozen_string_literal: true

# GET  /api/v1/private/incidents
# POST /api/v1/private/incidents
#
# Incidents the current person reported, newest first, and reporting a new one.
# A report names the property (residential_property_id) or one of the
# person's units (unit_id, which implies its property), optionally a common
# area of that property. Incidents::Report decides who may report where.
class Api::V1::Private::IncidentsController < Api::V1::Private::BaseController
  LIMIT = 50

  def index
    incidents = Incident.where(reported_by_person_id: person&.id)
                        .includes(:residential_property, :unit, :common_area)
                        .order(created_at: :desc)
                        .limit(LIMIT)

    render json: { data: serialize(incidents), categories: IncidentCategories::ALL }, status: :ok
  end

  def create
    unit = incident_params[:unit_id].present? ? Unit.find(incident_params[:unit_id]) : nil
    property = unit&.residential_property || ResidentialProperty.find(incident_params[:residential_property_id])
    area = incident_params[:common_area_id].present? ? CommonArea.where(residential_property_id: property.id).find(incident_params[:common_area_id]) : nil

    incident = Incidents::Report.call(
      property: property, unit: unit, common_area: area, actor: current_user,
      attributes: incident_params.slice(:category, :description, :priority)
    )

    render json: { data: serialize(incident) }, status: :created
  rescue Incidents::Report::NotAllowed
    render json: { error: I18n.t("api.incidents.not_allowed") }, status: :forbidden
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def serialize(resource)
    options = {}
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::IncidentSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end

  def incident_params
    params.require(:incident).permit(:residential_property_id, :unit_id, :common_area_id, :category, :description, :priority)
  end
end
