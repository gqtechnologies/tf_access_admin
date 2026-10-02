# frozen_string_literal: true

# GET /api/v1/private/units/:unit_id/parcels
#
# The unit's parcels as its residents see them: the ones still waiting at the
# front desk first, then those withdrawn in the last 30 days. Visible to anyone
# with an active occupancy or ownership of the unit; +can_withdraw+ tells the
# requester whether they may pick parcels up themselves.
class Api::V1::Private::Units::ParcelsController < Api::V1::Private::BaseController
  LIMIT = 50

  before_action :load_unit
  before_action :ensure_relationship!

  def index
    parcels = @unit.parcel_deliveries.includes(:unit, :withdrawn_by_person)
    waiting = parcels.waiting.order(received_at: :desc).limit(LIMIT).to_a
    withdrawn = parcels.recently_withdrawn.order(withdrawn_at: :desc).limit(LIMIT - waiting.size).to_a

    render json: {
      data: ActiveModelSerializers::SerializableResource.new(
        waiting + withdrawn, each_serializer: Api::Private::ParcelSerializer
      ).as_json,
      can_withdraw: Parcels::EligibleWithdrawers.include?(unit: @unit, person_id: @person&.id)
    }, status: :ok
  end

  private

  def load_unit
    @unit = Unit.find(params[:unit_id])
  end

  def ensure_relationship!
    @person = current_user.person_for(ActsAsTenant.current_tenant)

    return if Unit.with_active_relationship_for(@person, ActsAsTenant.current_tenant).exists?(id: @unit.id)

    render json: { error: I18n.t("api.visits.no_active_relationship") }, status: :forbidden
  end
end
