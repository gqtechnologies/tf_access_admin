# frozen_string_literal: true

# GET  /api/v1/private/concierge/shift?property_id=
# POST /api/v1/private/concierge/shift          (property_id)
# POST /api/v1/private/concierge/shift/close    (property_id, notes)
#
# The front-desk worker's own shift on an operated property: whether it is
# open, starting it and closing it with a handover note. The last closed shift
# of the property comes along so the next worker reads the handover.
class Api::V1::Private::Concierge::ShiftsController < Api::V1::Private::BaseController
  include Api::ConciergePropertyContext

  before_action :load_property!

  def show
    render json: { data: payload }, status: :ok
  end

  def create
    StaffShifts::Open.call(property: @property, actor: current_user)

    render json: { data: payload }, status: :created
  rescue StaffShifts::Open::NotAssigned
    render json: { error: I18n.t("api.shifts.not_assigned") }, status: :forbidden
  rescue StaffShifts::Open::AlreadyOpen
    render json: { error: I18n.t("api.shifts.already_open") }, status: :unprocessable_entity
  end

  def close
    shift = current_shift
    return render(json: { error: I18n.t("api.shifts.not_open") }, status: :unprocessable_entity) unless shift

    StaffShifts::Close.call(shift: shift, actor: current_user, notes: params[:notes])

    render json: { data: payload }, status: :ok
  rescue StaffShifts::Close::NotOpen
    render json: { error: I18n.t("api.shifts.not_open") }, status: :unprocessable_entity
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def current_shift
    person && StaffShift.open_now.find_by(person: person, residential_property: @property)
  end

  def payload
    shift = current_shift
    last = StaffShift.completed.where(residential_property: @property).includes(:person).order(actual_ends_at: :desc).first

    {
      current: shift && {
        id: shift.id,
        started_at: shift.actual_starts_at,
        parcels_received: shift.parcel_deliveries.count
      },
      last_handover: last && {
        person_name: last.person&.display_name,
        ended_at: last.actual_ends_at,
        notes: last.notes
      }
    }
  end
end
