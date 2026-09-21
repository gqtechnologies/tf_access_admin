# frozen_string_literal: true

# GET  /api/v1/private/concierge/visits?property_id=&tab=&q=&page=
# POST /api/v1/private/concierge/visits/:id/check_in
# POST /api/v1/private/concierge/visits/:id/check_out
# POST /api/v1/private/concierge/visits/:id/deny_entry
#
# JSON counterpart of the Inertia Concierge::VisitsController. Every query starts
# from VisitPolicy::Scope and the listing is pinned to one operated property;
# mutations delegate to Visits::CheckIn / Visits::CheckOut, which authorize
# through VisitPolicy.
class Api::V1::Private::Concierge::VisitsController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  TABS = [ VisitStatuses::AUTHORIZED, VisitStatuses::CHECKED_IN, VisitStatuses::CHECKED_OUT ].freeze
  PER_PAGE = 25

  before_action :load_property!, only: :index
  before_action :load_visit, only: %i[check_in check_out deny_entry]

  def index
    scoped = policy_scope(Visit).where(residential_property_id: @property.id)
    visits = apply_search(apply_tab(scoped))
               .includes(:unit, :authorized_by, visitor_person: { user: { avatar_attachment: :blob } })
               .page(params[:page])
               .per(PER_PAGE)

    render json: {
      data: serialize(visits),
      counters: counters(scoped),
      pagination: { page: visits.current_page, total_pages: visits.total_pages, total_count: visits.total_count }
    }, status: :ok
  end

  # The concierge only confirms "it is them": no operational fields. The
  # visitor's photo is mandatory on this channel — it is what gets verified.
  def check_in
    if @visit.visitor_person&.user&.avatar_path.blank?
      return render json: { error: I18n.t("api.concierge.photo_required") }, status: :unprocessable_entity
    end

    Visits::CheckIn.call(visit: @visit, actor: current_user)

    render json: { data: serialize(@visit) }, status: :ok
  rescue AASM::InvalidTransition
    render_invalid_transition
  rescue Visits::OperationalMetadataParams::InvalidMetadataError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue Pundit::NotAuthorizedError
    render_not_authorized
  end

  def check_out
    Visits::CheckOut.call(visit: @visit, actor: current_user, notes: check_out_params[:notes])

    render json: { data: serialize(@visit) }, status: :ok
  rescue AASM::InvalidTransition
    render_invalid_transition
  rescue Visits::OperationalMetadataParams::InvalidMetadataError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue Pundit::NotAuthorizedError
    render_not_authorized
  end

  # "It is not them": the visit stays authorized and only the host is told.
  def deny_entry
    Visits::DenyEntry.call(visit: @visit, actor: current_user)

    render json: { data: serialize(@visit) }, status: :ok
  rescue Visits::DenyEntry::NotDeniableError
    render_invalid_transition
  rescue Visits::DenyEntry::CooldownError => e
    response.set_header("Retry-After", e.retry_after.to_s)
    render json: { error: I18n.t("api.concierge.deny_cooldown") }, status: :too_many_requests
  rescue Pundit::NotAuthorizedError
    render_not_authorized
  end

  private

  # Out-of-scope visits (other property or tenant) raise RecordNotFound → 404.
  def load_visit
    @visit = policy_scope(Visit).includes(:unit, :authorized_by, visitor_person: { user: { avatar_attachment: :blob } }).find(params[:id])
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : VisitStatuses::AUTHORIZED
  end

  def apply_tab(scope)
    case tab
    when VisitStatuses::CHECKED_IN  then scope.currently_inside.order(checked_in_at: :desc)
    when VisitStatuses::CHECKED_OUT then scope.recently_checked_out.order(checked_out_at: :desc)
    else scope.where(status: VisitStatuses::AUTHORIZED).order(:scheduled_at)
    end
  end

  def apply_search(scope)
    query = params[:q].to_s.strip
    return scope if query.blank?

    Visits::ConciergeSearch.call(
      scope: scope,
      query: query,
      organization: ActsAsTenant.current_tenant,
      include_denied: false
    )
  end

  def counters(scoped)
    {
      authorized: scoped.where(status: VisitStatuses::AUTHORIZED).count,
      checked_in: scoped.currently_inside.count,
      checked_out: scoped.recently_checked_out.count
    }
  end

  def serialize(resource)
    options = { scope: current_user }
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::ConciergeVisitSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end

  def check_out_params
    params.fetch(:check_out, {}).permit(:notes)
  end

  def render_invalid_transition
    render json: { error: I18n.t("api.concierge.invalid_transition") }, status: :unprocessable_entity
  end

  def render_not_authorized
    render json: { error: I18n.t("api.concierge.not_authorized") }, status: :forbidden
  end
end
