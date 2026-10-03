# frozen_string_literal: true

# The administration's incident queue for one property: open, in progress and
# closed, each row editable in a drawer (status, priority, assignee,
# resolution). Closing one tells whoever reported it.
class Admin::IncidentsController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_INCIDENTS
  TABS = %w[open in_progress closed].freeze

  def index
    authorize Incident

    property = active_managed_property(CAPABILITY)
    scoped = property ? policy_scope(Incident).where(residential_property_id: property.id) : Incident.none
    incidents = apply_tab(scoped)
                  .includes(:unit, :common_area, :reported_by_person, :assigned_to_person)
                  .page(@filters[:page])
                  .per(@filters[:per_page])

    render inertia: "admin/incidents/index", props: {
      incidents: incidents.map { |incident| serialize(incident) },
      pagination: pagination_info(incidents),
      tab: tab,
      counters: TABS.index_with { |name| apply_tab(scoped, name).count },
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property),
      assignees: property ? assignees_for(property) : [],
      categories: IncidentCategories::ALL,
      priorities: Priorities::ALL
    }
  end

  def update
    incident = policy_scope(Incident).find(params[:id])
    Incidents::Update.call(incident: incident, actor: current_user, attributes: incident_params)

    redirect_to admin_incidents_path(property_id: incident.residential_property_id, tab: params[:tab].presence)
  rescue Incidents::Update::ResolutionRequired
    redirect_with_error(incident, t("frontend.admin.incidents.errors.resolution_required"))
  rescue ActiveRecord::RecordInvalid => e
    redirect_with_error(incident, e.record.errors.full_messages.to_sentence)
  rescue ActiveRecord::RecordNotFound, Pundit::NotAuthorizedError
    redirect_to admin_incidents_path, inertia: { errors: { base: [ t("frontend.admin.incidents.errors.not_found") ] } }
  end

  private

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : "open"
  end

  def apply_tab(scope, name = tab)
    case name
    when "in_progress" then scope.where(status: IncidentStatuses::IN_PROGRESS).order(updated_at: :desc)
    when "closed" then scope.where(status: IncidentStatuses::CLOSED).order(resolved_at: :desc)
    else scope.where(status: IncidentStatuses::OPEN).order(created_at: :desc)
    end
  end

  # Who an incident can be assigned to: the property's staff and the
  # organization's people holding manage_incidents there — kept simple as the
  # people with an active staff assignment on the property plus the current user.
  def assignees_for(property)
    people = Person.where(id: StaffAssignment.where(residential_property_id: property.id).currently_active.select(:person_id)).to_a
    me = current_user.person_for(Current.organization)
    people << me if me && people.none? { |person| person.id == me.id }

    people.sort_by { |person| person.display_name.to_s.downcase }.map { |person| { id: person.id, name: person.display_name } }
  end

  def serialize(incident)
    {
      id: incident.id,
      category: incident.category,
      description: incident.description,
      priority: incident.priority,
      status: incident.status,
      resolution: incident.resolution,
      created_at: incident.created_at,
      resolved_at: incident.resolved_at,
      unit: incident.unit && (incident.unit.display_name.presence || incident.unit.identifier),
      common_area: incident.common_area&.name,
      reported_by_name: incident.reported_by_person&.display_name,
      assigned_to_person_id: incident.assigned_to_person_id,
      assigned_to_name: incident.assigned_to_person&.display_name
    }
  end

  def incident_params
    params.fetch(:incident, {}).permit(:status, :priority, :assigned_to_person_id, :resolution)
  end

  def redirect_with_error(incident, message)
    redirect_to admin_incidents_path(property_id: incident&.residential_property_id, tab: params[:tab].presence),
                inertia: { errors: { base: [ message ] } }
  end
end
