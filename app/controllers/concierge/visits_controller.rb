# frozen_string_literal: true

# Operational controller for concierge-facing visit workflow.
#
# Surfaces: index (operational list scoped to assigned property),
# show (restricted detail), check_in and check_out.
#
# Concierge actors cannot create, update, authorize or cancel (§5.6 / §6.1).
# The policy scope already filters to operational statuses for concierge users.
class Concierge::VisitsController < AdminController
  before_action :set_visit, only: %i[show check_in check_out]

  # GET /concierge/visits (6.1, 6.4)
  # Operational listing: authorized + checked_in + recent checked_out on assigned properties.
  def index
    authorize Visit
    @q = policy_scope(Visit).ransack(params[:q])
    visits = @q.result(distinct: true)
               .order(scheduled_at: :asc)
               .page(@filters[:page])
               .per(@filters[:per_page])

    render inertia: "concierge/visits/index", props: {
      visits: serialize_visits(visits),
      pagination: pagination_info(visits),
      filters: params[:q].to_h
    }
  end

  # GET /concierge/visits/:id (6.1, 6.4)
  def show
    authorize @visit

    render inertia: "concierge/visits/show", props: {
      visit: serialize_visit(@visit)
    }
  end

  # POST /concierge/visits/:id/check_in (6.1, 6.5, 6.6, 6.7)
  def check_in
    Visits::CheckIn.call(
      visit: @visit,
      actor: current_user,
      access_point: check_in_params[:access_point],
      access_type: check_in_params[:access_type],
      vehicle_plate: check_in_params[:vehicle_plate],
      notes: check_in_params[:notes],
      check_in_metadata: check_in_params[:metadata]&.to_h || {}
    )
    redirect_to concierge_visit_path(@visit)
  rescue AASM::InvalidTransition
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.invalid_transition") ] } }
  rescue Visits::OperationalMetadataParams::InvalidMetadataError => e
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ e.message ] } }
  rescue Pundit::NotAuthorizedError
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_authorized") ] } }
  end

  # POST /concierge/visits/:id/check_out (6.1, 6.5, 6.6, 6.7)
  def check_out
    Visits::CheckOut.call(
      visit: @visit,
      actor: current_user,
      access_point: check_out_params[:access_point],
      incident_type: check_out_params[:incident_type],
      notes: check_out_params[:notes],
      check_out_metadata: check_out_params[:metadata]&.to_h || {}
    )
    redirect_to concierge_visit_path(@visit)
  rescue AASM::InvalidTransition
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.invalid_transition") ] } }
  rescue Visits::OperationalMetadataParams::InvalidMetadataError => e
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ e.message ] } }
  rescue Pundit::NotAuthorizedError
    redirect_to concierge_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_authorized") ] } }
  end

  private

  def set_visit
    @visit = policy_scope(Visit).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to concierge_visits_path,
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_found") ] } }
  end

  def check_in_params
    p = params[:check_in] ? params.require(:check_in) : ActionController::Parameters.new
    p.permit(:access_point, :access_type, :vehicle_plate, :notes, metadata: {})
  end

  def check_out_params
    p = params[:check_out] ? params.require(:check_out) : ActionController::Parameters.new
    p.permit(:access_point, :incident_type, :notes, metadata: {})
  end

  def serialize_visit(visit)
    Concierge::VisitSerializer.new(visit, current_user: current_user).as_json
  end

  def serialize_visits(visits)
    visits.map { |v| Concierge::VisitSerializer.new(v, current_user: current_user).as_json }
  end
end
