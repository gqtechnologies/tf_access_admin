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
    scoped = apply_admin_scope(policy_scope(Visit))
    @q = scoped.ransack(params[:q])
    visits = @q.result(distinct: true)
               .includes(:visitor_person, :host_person, :unit, :residential_property, :checked_in_by, :visit_status_histories)
               .order(scheduled_at: :desc)
               .page(@filters[:page])
               .per(@filters[:per_page])

    render inertia: "admin/visits/index", props: {
      visits: serialize_visits(visits),
      pagination: pagination_info(visits),
      filters: params[:q].to_h,
      scope: admin_scope_param,
      show_scope_selector: show_admin_scope_selector?,
      can_create: policy(Visit).create?,
      properties: accessible_properties_for_filters,
      units: filter_units,
      statuses: VisitStatuses::MVP
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

  ADMIN_SCOPES = %w[organization assigned].freeze

  def admin_scope_param
    return "organization" unless show_admin_scope_selector?

    scope = params[:scope].to_s.presence || "organization"
    ADMIN_SCOPES.include?(scope) ? scope : "organization"
  end

  def show_admin_scope_selector?
    resolver = Authorization::Resolver.new(user: current_user, organization: Current.organization)
    org_wide = resolver.allowed?(:manage_visits) || resolver.allowed?(:view_visits)
    org_wide && managed_property_ids.any?
  end

  def apply_admin_scope(scope)
    return scope unless show_admin_scope_selector?
    return scope unless admin_scope_param == "assigned"

    ids = managed_property_ids
    return scope.none if ids.empty?

    scope.where(residential_property_id: ids)
  end

  def managed_property_ids
    profile = Authorization::GrantProfile.build(current_user, Current.organization)
    profile.property_capabilities
           .select { |_, caps| caps.include?(Authorization::Capabilities::MANAGE_VISITS) }
           .keys
  end

  def accessible_properties_for_filters
    ids = policy_scope(ResidentialProperty).pluck(:id, :name)
    ids.map { |id, name| { id: id, name: name } }
  end

  def filter_units
    units_scope = policy_scope(Unit).order(:identifier)
    property_id = params.dig(:q, :residential_property_id_eq).presence
    units_scope = units_scope.where(residential_property_id: property_id) if property_id.present?

    units_scope.limit(500).map do |unit|
      { id: unit.id, identifier: unit.identifier, display_name: unit.display_name, residential_property_id: unit.residential_property_id }
    end
  end
end
