# frozen_string_literal: true

# GET /api/v1/private/units/:unit_id/residents
#
# Read-only list of the people with an active occupancy or ownership of the
# unit. Visible only to someone who holds such a relationship themselves —
# the same rule that decides which units GET /units returns.
class Api::V1::Private::Units::ResidentsController < Api::V1::Private::BaseController
  before_action :load_unit
  before_action :ensure_relationship!

  def index
    render json: { data: Residents::UnitResidents.call(unit: @unit, viewer: @person) }, status: :ok
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
