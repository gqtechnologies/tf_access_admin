# frozen_string_literal: true

# GET /api/v1/private/common_areas?unit_id=
# GET /api/v1/private/common_areas/:id/availability?day=YYYY-MM-DD
#
# The bookable common areas of a unit's property, with the rules the app needs
# to offer valid slots, and the slots already taken on a given day. Visible to
# anyone with an active relationship with the unit; +can_reserve+ says whether
# the requester may book for it.
class Api::V1::Private::CommonAreasController < Api::V1::Private::BaseController
  before_action :load_unit, only: :index
  before_action :load_area, only: :availability

  def index
    areas = CommonArea.active.where(residential_property_id: @unit.residential_property_id)
                      .includes(:common_area_rules).order(:name)

    render json: {
      data: areas.map { |area| serialize(area) },
      can_reserve: Reservations::Request.eligible?(person: person, unit: @unit),
      time_zone: @unit.residential_property.timezone
    }, status: :ok
  end

  def availability
    day = Date.iso8601(params[:day].to_s)
    range = @area.time_zone.local(day.year, day.month, day.day).all_day
    taken = @area.common_area_reservations.holding_slot
                 .where("starts_at < ? AND ends_at > ?", range.end, range.begin)
                 .order(:starts_at)

    render json: { data: taken.map { |r| { starts_at: r.starts_at, ends_at: r.ends_at, status: r.status } } }, status: :ok
  rescue Date::Error
    render json: { error: I18n.t("api.errors.invalid_day") }, status: :unprocessable_entity
  end

  private

  def person
    @person ||= current_user.person_for(ActsAsTenant.current_tenant)
  end

  def property_ids_with_relationship
    Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant).distinct.pluck(:residential_property_id)
  end

  def load_unit
    @unit = Unit.with_active_relationship_for(person, ActsAsTenant.current_tenant).find(params[:unit_id])
  end

  def load_area
    @area = CommonArea.active.where(residential_property_id: property_ids_with_relationship).find(params[:id])
  end

  def serialize(area)
    {
      id: area.id,
      name: area.name,
      area_type: area.area_type,
      capacity: area.capacity,
      requires_approval: area.requires_approval?,
      rules: area.rules
    }
  end
end
