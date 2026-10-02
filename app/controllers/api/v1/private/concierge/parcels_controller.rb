# frozen_string_literal: true

# GET  /api/v1/private/concierge/parcels?property_id=&tab=&q=&page=
# POST /api/v1/private/concierge/parcels
# GET  /api/v1/private/concierge/parcels/:id
# POST /api/v1/private/concierge/parcels/:id/withdraw
#
# Front-desk parcel operation. Listing and registration are pinned to one
# property where the actor holds manage_parcels; single-parcel routes resolve
# through ParcelDeliveryPolicy::Scope, so a parcel of another property is a 404.
# Mutations delegate to Parcels::Receive / Parcels::Withdraw.
class Api::V1::Private::Concierge::ParcelsController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  TABS = [ ParcelStatuses::RECEIVED, ParcelStatuses::WITHDRAWN ].freeze
  PER_PAGE = 25

  before_action :load_parcel_property!, only: %i[index create]
  before_action :load_parcel, only: %i[show withdraw]

  def index
    scoped = policy_scope(ParcelDelivery).where(residential_property_id: @property.id)
    parcels = apply_search(apply_tab(scoped))
                .includes(:unit, :withdrawn_by_person)
                .page(params[:page])
                .per(PER_PAGE)

    render json: {
      data: serialize(parcels),
      counters: { received: scoped.waiting.count, withdrawn: scoped.recently_withdrawn.count },
      pagination: { page: parcels.current_page, total_pages: parcels.total_pages, total_count: parcels.total_count }
    }, status: :ok
  end

  def show
    render json: { data: detail(@parcel) }, status: :ok
  end

  def create
    unit = @property.units.find(parcel_params[:unit_id])
    parcel = Parcels::Receive.call(unit: unit, actor: current_user, attributes: parcel_params.except(:unit_id))

    render json: { data: serialize(parcel) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue Pundit::NotAuthorizedError
    render_not_authorized
  end

  def withdraw
    Parcels::Withdraw.call(parcel: @parcel, actor: current_user, person_id: params[:person_id])

    render json: { data: detail(@parcel) }, status: :ok
  rescue Parcels::Withdraw::NotWaitingError
    render json: { error: I18n.t("api.parcels.not_waiting") }, status: :unprocessable_entity
  rescue Parcels::Withdraw::NotEligibleError
    render json: { error: I18n.t("api.parcels.not_eligible") }, status: :unprocessable_entity
  rescue Pundit::NotAuthorizedError
    render_not_authorized
  end

  private

  def load_parcel
    @parcel = policy_scope(ParcelDelivery).includes(:unit, :withdrawn_by_person).find(params[:id])
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : ParcelStatuses::RECEIVED
  end

  def apply_tab(scope)
    if tab == ParcelStatuses::WITHDRAWN
      scope.recently_withdrawn.order(withdrawn_at: :desc)
    else
      scope.waiting.order(received_at: :desc)
    end
  end

  def apply_search(scope)
    query = params[:q].to_s.strip
    return scope if query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.joins(:unit).where(
      "units.identifier ILIKE :q OR units.display_name ILIKE :q OR " \
      "parcel_deliveries.courier_company ILIKE :q OR parcel_deliveries.tracking_code ILIKE :q",
      q: pattern
    )
  end

  def serialize(resource)
    options = {}
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::ParcelSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end

  # Single-parcel payload: adds who may pick it up while it is still waiting.
  def detail(parcel)
    withdrawers = parcel.waiting? ? Parcels::EligibleWithdrawers.call(unit: parcel.unit).includes(:user) : []

    serialize(parcel).merge(
      eligible_withdrawers: withdrawers.map do |person|
        { id: person.id, name: person.display_name, avatar_url: person.user&.avatar_path }
      end
    )
  end

  def parcel_params
    params.require(:parcel).permit(:unit_id, :delivery_type, :courier_company, :tracking_code, :notes)
  end

  def render_not_authorized
    render json: { error: I18n.t("api.parcels.not_authorized") }, status: :forbidden
  end
end
