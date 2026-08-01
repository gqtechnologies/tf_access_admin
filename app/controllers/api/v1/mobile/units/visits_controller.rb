# frozen_string_literal: true

# POST /api/v1/mobile/units/:unit_id/visits
#
# Mobile-native equivalent of Api::V1::Private::Units::VisitsController#create.
# Unlike the private endpoint, no tenant is set by the time this action runs —
# the mobile namespace never resolves a tenant from the request (see
# Api::V1::Mobile::BaseController) — so the unit's organization is resolved
# from the unit itself and used to open an explicit ActsAsTenant.with_tenant
# block around authorization and creation.
class Api::V1::Mobile::Units::VisitsController < Api::V1::Mobile::BaseController
  def create
    unit = ActsAsTenant.without_tenant { Unit.find(params[:unit_id]) }

    ActsAsTenant.with_tenant(unit.organization) do
      visit_context = Residents::VisitContext.new(
        user: current_user,
        organization: unit.organization,
        unit: unit
      )

      unless visit_context.authorized?
        return render json: { error: I18n.t("api.visits.#{visit_context.denial_reason}") },
                      status: :forbidden
      end

      visit = Residents::CreateAuthorizedVisit.call(
        unit:           unit,
        visitor_params: visit_params[:visitor],
        scheduled_at:   visit_params[:scheduled_at],
        actor:          current_user
      )

      render json: { data: { id: visit.id, status: visit.status } }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def visit_params
    params.require(:visit).permit(
      :scheduled_at,
      visitor: %i[name document phone]
    )
  end
end
