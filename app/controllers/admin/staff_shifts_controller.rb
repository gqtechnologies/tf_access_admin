# frozen_string_literal: true

# The administration's log of front-desk shifts for one property and day: who
# was on duty, from when to when, the handover note and the parcels received.
class Admin::StaffShiftsController < AdminController
  include ManagedPropertyContext

  CAPABILITY = Authorization::Capabilities::MANAGE_STAFF_ASSIGNMENTS

  def index
    authorize StaffShift

    property = active_managed_property(CAPABILITY)
    zone = property ? (ActiveSupport::TimeZone[property.timezone.to_s] || Time.zone) : Time.zone
    day = parse_day(zone)
    range = zone.local(day.year, day.month, day.day).all_day

    shifts = if property
      StaffShift.where(residential_property: property)
                .where("staff_shifts.actual_starts_at <= ? AND (staff_shifts.actual_ends_at IS NULL OR staff_shifts.actual_ends_at >= ?)", range.end, range.begin)
                .includes(:person)
                .order(:actual_starts_at)
    else
      StaffShift.none
    end
    parcel_counts = ParcelDelivery.where(staff_shift_id: shifts.map(&:id)).group(:staff_shift_id).count

    render inertia: "admin/staff_shifts/index", props: {
      shifts: shifts.map { |shift| serialize(shift, parcel_counts[shift.id] || 0) },
      day: day.iso8601,
      time_zone: zone.tzinfo.name,
      properties: managed_properties_for(CAPABILITY).map { |p| property_summary(p) },
      active_property: property_summary(property)
    }
  end

  private

  def parse_day(zone)
    Date.iso8601(params[:day].to_s)
  rescue Date::Error
    zone.today
  end

  def serialize(shift, parcels)
    {
      id: shift.id,
      person_name: shift.person&.display_name,
      status: shift.status,
      started_at: shift.actual_starts_at,
      ended_at: shift.actual_ends_at,
      notes: shift.notes,
      parcels_received: parcels
    }
  end
end
