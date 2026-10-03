# frozen_string_literal: true

require_relative "announcement_test_helper"

# A property with a bookable common area and residents with and without the
# reservation permission. Times are built in the property's zone (Santiago).
module ReservationTestHelper
  include AnnouncementTestHelper

  def setup_reservation_world(prefix)
    setup_announcement_world(prefix)

    @booker = parcel_member("#{prefix.downcase}-booker@example.test", "Bea Booker")
    UnitOccupancy.create!(
      organization: @organization, person: person_of(@booker), unit: @unit,
      occupancy_type: OccupancyTypes::TENANT, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_reserve_common_areas: true
    )
    @area = create_area(name: "Quincho", requires_approval: true)
  end

  def create_area(property: @property, rules: {}, **attrs)
    area = CommonArea.create!(
      organization: @organization, residential_property: property,
      name: attrs.delete(:name) || "Sala", area_type: attrs.delete(:area_type) || CommonAreaTypes::BBQ,
      status: CommonArea::STATUS_ACTIVE, **attrs
    )
    rules.each do |type, value|
      area.common_area_rules.create!(
        organization: @organization, rule_type: type.to_s,
        **(value.is_a?(Integer) ? { value_int: value } : { value_text: value })
      )
    end
    area
  end

  def zone
    ActiveSupport::TimeZone[@property.timezone]
  end

  # Local time in the property's zone, +days+ from today.
  def local_at(days, hour, minute = 0)
    (zone.now.beginning_of_day + days.days).change(hour: hour, min: minute)
  end

  def book(area: @area, unit: @unit, person: person_of(@booker), from: local_at(3, 18), to: local_at(3, 21), guests: 5)
    Reservations::Request.call(area: area, unit: unit, person: person, starts_at: from, ends_at: to, guest_count: guests)
  end
end
