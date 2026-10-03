# frozen_string_literal: true

# GET  /api/v1/private/reservations?unit_id=
# POST /api/v1/private/reservations
# POST /api/v1/private/reservations/:id/cancel
#
# A unit's common area reservations, booking and cancelling. Listing needs an
# active relationship with the unit; booking also needs the occupancy's
# can_reserve_common_areas (Reservations::Request); cancelling is for the
# resident who booked.
class Api::V1::Private::ReservationsController < Api::V1::Private::BaseController
  LIMIT = 50

  def index
    unit = units_with_relationship.find(params[:unit_id])
    reservations = unit.common_area_reservations
                       .includes(:common_area, :unit)
                       .where(ends_at: 30.days.ago..)
                       .order(starts_at: :desc)
                       .limit(LIMIT)

    render json: { data: serialize(reservations) }, status: :ok
  end

  def create
    unit = units_with_relationship.find(reservation_params[:unit_id])
    area = CommonArea.where(residential_property_id: unit.residential_property_id).find(reservation_params[:common_area_id])

    reservation = Reservations::Request.call(
      area: area,
      unit: unit,
      person: person,
      starts_at: parse_time(reservation_params[:starts_at]),
      ends_at: parse_time(reservation_params[:ends_at]),
      guest_count: reservation_params[:guest_count]
    )

    render json: { data: serialize(reservation) }, status: :created
  rescue Reservations::Request::NotEligible
    render json: { error: I18n.t("api.reservations.not_eligible") }, status: :forbidden
  rescue Reservations::Request::SlotTaken
    render json: { error: I18n.t("api.reservations.slot_taken"), code: "slot_taken" }, status: :conflict
  rescue Reservations::RuleCheck::Violation => e
    render json: { error: e.message_text, code: e.key.to_s }, status: :unprocessable_entity
  end

  def cancel
    reservation = CommonAreaReservation.where(unit_id: units_with_relationship.select(:id)).find(params[:id])
    Reservations::Cancel.call(reservation: reservation, actor: current_user)

    render json: { data: serialize(reservation) }, status: :ok
  rescue Reservations::Cancel::NotCancellable
    render json: { error: I18n.t("api.reservations.not_cancellable") }, status: :unprocessable_entity
  rescue Pundit::NotAuthorizedError
    render json: { error: I18n.t("api.reservations.not_requester") }, status: :forbidden
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def units_with_relationship
    Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant)
  end

  def parse_time(value)
    Time.zone.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def serialize(resource)
    options = { viewer: person }
    options[resource.respond_to?(:each) ? :each_serializer : :serializer] = Api::Private::ReservationSerializer

    ActiveModelSerializers::SerializableResource.new(resource, **options).as_json
  end

  def reservation_params
    params.require(:reservation).permit(:unit_id, :common_area_id, :starts_at, :ends_at, :guest_count)
  end
end
