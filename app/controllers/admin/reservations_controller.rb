# frozen_string_literal: true

# The administration's view of common area reservations for one property:
# pending ones to approve or reject, upcoming approved ones (cancellable), and
# the history. Decisions push the outcome to the resident who booked.
class Admin::ReservationsController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_COMMON_AREAS
  TABS = %w[pending upcoming history].freeze

  before_action :set_reservation, only: %i[approve reject cancel]

  def index
    authorize CommonArea

    property = active_managed_property(CAPABILITY)
    scoped = property ? reservations_of(property) : CommonAreaReservation.none
    reservations = apply_tab(scoped)
                     .includes(:common_area, :unit, :requested_by_person)
                     .page(@filters[:page])
                     .per(@filters[:per_page])

    render inertia: "admin/reservations/index", props: {
      reservations: reservations.map { |reservation| serialize(reservation) },
      pagination: pagination_info(reservations),
      tab: tab,
      counters: TABS.index_with { |name| apply_tab(scoped, name).count },
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property)
    }
  end

  def approve
    Reservations::Decide.call(reservation: @reservation, actor: current_user, decision: :approve)
    redirect_to list_path(tab: "pending")
  rescue Reservations::Decide::NotPending, Pundit::NotAuthorizedError
    redirect_with_errors(t("frontend.admin.reservations.errors.not_pending"))
  end

  def reject
    Reservations::Decide.call(reservation: @reservation, actor: current_user, decision: :reject, reason: params[:reason])
    redirect_to list_path(tab: "pending")
  rescue Reservations::Decide::NotPending, Pundit::NotAuthorizedError
    redirect_with_errors(t("frontend.admin.reservations.errors.not_pending"))
  end

  def cancel
    Reservations::Cancel.call(reservation: @reservation, actor: current_user, reason: params[:reason])
    redirect_to list_path(tab: "upcoming")
  rescue Reservations::Cancel::NotCancellable, Pundit::NotAuthorizedError
    redirect_with_errors(t("frontend.admin.reservations.errors.not_cancellable"))
  end

  private

  def set_reservation
    area_ids = policy_scope(CommonArea).select(:id)
    @reservation = CommonAreaReservation.where(common_area_id: area_ids).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_with_errors(t("frontend.admin.reservations.errors.not_found"))
  end

  def reservations_of(property)
    CommonAreaReservation.where(common_area_id: policy_scope(CommonArea).where(residential_property_id: property.id).select(:id))
  end

  def tab
    TABS.include?(params[:tab].to_s) ? params[:tab].to_s : "pending"
  end

  def apply_tab(scope, name = tab)
    now = Time.zone.now
    case name
    when "upcoming"
      scope.where(status: ReservationStatuses::APPROVED).where(ends_at: now..).order(:starts_at)
    when "history"
      scope.where("common_area_reservations.ends_at < ? OR common_area_reservations.status IN (?)",
                  now, [ ReservationStatuses::REJECTED, ReservationStatuses::CANCELLED ])
           .order(starts_at: :desc)
    else
      scope.where(status: ReservationStatuses::PENDING).where(ends_at: now..).order(:starts_at)
    end
  end

  def serialize(reservation)
    {
      id: reservation.id,
      status: reservation.status,
      starts_at: reservation.starts_at,
      ends_at: reservation.ends_at,
      guest_count: reservation.guest_count,
      rejection_reason: reservation.rejection_reason,
      common_area: { id: reservation.common_area_id, name: reservation.common_area.name },
      unit: { id: reservation.unit_id, name: reservation.unit.display_name.presence || reservation.unit.identifier },
      requested_by_name: reservation.requested_by_person&.display_name,
      time_zone: reservation.common_area.residential_property.timezone
    }
  end

  def list_path(tab: nil)
    admin_reservations_path({ property_id: @reservation&.residential_property_id || params[:property_id], tab: tab }.compact)
  end

  def redirect_with_errors(message)
    redirect_to list_path(tab: params[:tab].presence), inertia: { errors: { base: [ message ] } }
  end
end
