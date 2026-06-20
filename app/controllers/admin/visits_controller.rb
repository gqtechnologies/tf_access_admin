# frozen_string_literal: true

# Administrative controller for Visit management.
#
# Surfaces: index (org/property-scoped list), show (full detail), new/create,
# edit/update (editable states), and member actions authorize/cancel.
# Check-in and check-out are handled by Admin::Visits::CheckInsController and
# Admin::Visits::CheckOutsController so they can carry operational metadata.
#
# Authorization delegation:
#   - `authorize` / `policy_scope` come from Pundit (included via AdminController → InertiaController).
#   - Domain logic (transitions, events, actor stamping) is delegated to the Visits::* service objects.
#
# Error contract (6.6):
#   - Policy denial  → rescued globally; here we also handle it explicitly with a 403 flash.
#   - AASM invalid   → rescued and surfaced as Inertia errors.
#   - Validation     → model errors redirected back with `inertia: { errors: }`.
#   - Metadata       → Visits::OperationalMetadataParams::InvalidMetadataError handled in sub-controllers.
class Admin::VisitsController < AdminController
  # Editable statuses: only pending and authorized may be updated via the admin form.
  EDITABLE_STATUSES = [ VisitStatuses::PENDING, VisitStatuses::AUTHORIZED ].freeze

  before_action :set_visit, only: %i[show edit update authorize_visit cancel]
  before_action :require_editable_status!, only: %i[edit update]

  # GET /admin/visits
  # Administrative listing — all org or property-scoped visits (6.1, 6.4).
  def index
    authorize Visit
    @q = policy_scope(Visit).ransack(params[:q])
    visits = @q.result(distinct: true)
               .order(scheduled_at: :desc)
               .page(@filters[:page])
               .per(@filters[:per_page])

    scoped = policy_scope(Visit)
    render inertia: "admin/visits/index", props: {
      visits: serialize_visits(visits),
      pagination: pagination_info(visits),
      filters: params[:q].to_h,
      counters: visit_counters(scoped)
    }
  end

  # GET /admin/visits/:id
  # Full or restricted detail depending on full_detail? / restricted_detail? (6.1, 6.4).
  def show
    authorize @visit

    render inertia: "admin/visits/show", props: {
      visit: serialize_visit_detail(@visit)
    }
  end

  # GET /admin/visits/new
  def new
    authorize Visit

    render inertia: "admin/visits/new", props: {
      visit: Admin::VisitSerializer.new(Visit.new, current_user: current_user).as_json
    }
  end

  # POST /admin/visits (6.1, 6.2, 6.5, 6.6)
  def create
    authorize Visit

    unit = policy_scope(Unit).find(visit_params[:unit_id])
    visit = Visits::Create.call(
      unit: unit,
      visit_params: visit_params.except(:unit_id),
      actor: current_user
    )
    redirect_to admin_visit_path(visit)
  rescue ActiveRecord::RecordNotFound
    redirect_to new_admin_visit_path,
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.unit_not_found") ] } }
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_admin_visit_path,
                inertia: { errors: e.record.errors.to_h }
  rescue Pundit::NotAuthorizedError
    redirect_to new_admin_visit_path,
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_authorized") ] } }
  end

  # GET /admin/visits/:id/edit (6.3)
  # Editable only while visit is pending or authorized.
  def edit
    authorize @visit

    render inertia: "admin/visits/edit", props: {
      visit: serialize_visit_detail(@visit)
    }
  end

  # PATCH/PUT /admin/visits/:id (6.3, 6.6)
  def update
    authorize @visit

    unless @visit.update(update_params)
      redirect_to edit_admin_visit_path(@visit), inertia: { errors: @visit.errors.to_h }
      return
    end

    redirect_to admin_visit_path(@visit)
  end

  # POST /admin/visits/:id/authorize (6.1, 6.6)
  def authorize_visit
    Visits::Authorize.call(visit: @visit, actor: current_user, notes: params[:notes])
    redirect_to admin_visit_path(@visit)
  rescue AASM::InvalidTransition
    redirect_to admin_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.invalid_transition") ] } }
  rescue Pundit::NotAuthorizedError
    redirect_to admin_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_authorized") ] } }
  end

  # DELETE /admin/visits/:id/cancel (6.1, 6.6)
  def cancel
    Visits::Cancel.call(visit: @visit, actor: current_user, notes: params[:notes])
    redirect_to admin_visits_path
  rescue AASM::InvalidTransition
    redirect_to admin_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.invalid_transition") ] } }
  rescue Pundit::NotAuthorizedError
    redirect_to admin_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_authorized") ] } }
  end

  private

  def set_visit
    @visit = policy_scope(Visit).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_visits_path,
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_found") ] } }
  end

  def require_editable_status!
    return if @visit.nil? # guard for redirect already issued in set_visit
    return if EDITABLE_STATUSES.include?(@visit.status)

    redirect_to admin_visit_path(@visit),
                inertia: { errors: { base: [ t("frontend.admin.visits.errors.not_editable") ] } }
  end

  def visit_params
    params.require(:visit).permit(
      :unit_id, :visitor_person_id, :host_person_id,
      :scheduled_at, :valid_from, :valid_until,
      :visit_type, :notes,
      metadata: {}
    )
  end

  def update_params
    params.require(:visit).permit(
      :visitor_person_id, :host_person_id,
      :scheduled_at, :valid_from, :valid_until,
      :visit_type, :notes,
      metadata: {}
    )
  end

  def serialize_visit_detail(visit)
    policy = VisitPolicy.new(current_user, visit)
    serializer_class = policy.full_detail? ? Admin::VisitDetailSerializer : Admin::VisitRestrictedSerializer
    serializer_class.new(visit, current_user: current_user, policy: policy).as_json
  end

  def serialize_visits(visits)
    visits.map { |v| Admin::VisitSerializer.new(v, current_user: current_user).as_json }
  end

  def visit_counters(scoped)
    {
      authorized: scoped.where(status: VisitStatuses::AUTHORIZED).count,
      checked_in: scoped.where(status: VisitStatuses::CHECKED_IN).count,
      recent_checked_out: scoped.recently_checked_out.count
    }
  end
end
