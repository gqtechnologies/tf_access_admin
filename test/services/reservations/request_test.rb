# frozen_string_literal: true

require "test_helper"

class Reservations::RequestTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup { setup_reservation_world("RQ") }

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "an area that needs approval leaves the booking pending, with history" do
    reservation = book

    assert_equal ReservationStatuses::PENDING, reservation.status
    assert_nil reservation.approved_at
    assert_equal @property.id, reservation.residential_property_id
    assert_equal [ nil, "pending" ], reservation.common_area_reservation_status_histories.sole.then { |h| [ h.from_status, h.to_status ] }
  end

  test "an area without approval confirms the booking on the spot" do
    open_area = create_area(name: "Gimnasio", requires_approval: false)

    reservation = book(area: open_area)

    assert_equal ReservationStatuses::APPROVED, reservation.status
    assert reservation.approved_at.present?
  end

  test "only occupants with the reservation permission may book" do
    [ person_of(@relative), person_of(@owner), person_of(@picker) ].each do |person|
      assert_raises(Reservations::Request::NotEligible) { book(person: person) }
    end
  end

  test "an area of another property cannot be booked for the unit" do
    foreign = create_area(property: @property_q, name: "Otra")

    assert_raises(Reservations::Request::NotEligible) { book(area: foreign) }
  end

  test "an overlapping slot is taken, a back-to-back one is fine" do
    book(from: local_at(3, 18), to: local_at(3, 21))

    assert_raises(Reservations::Request::SlotTaken) { book(from: local_at(3, 20), to: local_at(3, 22)) }
    assert book(from: local_at(3, 21), to: local_at(3, 23)).persisted?
  end

  test "a rejected or cancelled booking frees the slot" do
    first = book
    first.update_column(:status, ReservationStatuses::CANCELLED)

    assert book.persisted?
  end

  test "rules are enforced in the property's time zone" do
    area = create_area(
      name: "Sala de eventos",
      capacity: 10,
      rules: { opens_at: "10:00", closes_at: "22:00", max_duration_minutes: 180, min_advance_hours: 24, max_reservations_per_month: 1 }
    )

    {
      capacity: -> { book(area: area, guests: 11) },
      opening_hours: -> { book(area: area, from: local_at(3, 9), to: local_at(3, 11)) },
      max_duration: -> { book(area: area, from: local_at(3, 12), to: local_at(3, 16)) },
      min_advance: -> { book(area: area, from: 2.hours.from_now, to: 4.hours.from_now) },
      in_the_past: -> { book(area: area, from: 2.hours.ago, to: 1.hour.ago) },
      invalid_range: -> { book(area: area, from: local_at(3, 14), to: local_at(3, 13)) }
    }.each do |key, attempt|
      error = assert_raises(Reservations::RuleCheck::Violation, key.to_s) { attempt.call }
      assert_equal key, error.key
    end

    reservation_day = local_at(3, 0)
    book(area: area, from: reservation_day.change(hour: 12), to: reservation_day.change(hour: 14))
    second_day = reservation_day + 1.day
    second_day = reservation_day - 1.day unless second_day.month == reservation_day.month
    error = assert_raises(Reservations::RuleCheck::Violation) do
      book(area: area, from: second_day.change(hour: 12), to: second_day.change(hour: 14))
    end
    assert_equal :monthly_limit, error.key
  end

  test "an inactive area cannot be booked" do
    @area.update!(status: CommonArea::STATUS_INACTIVE)

    error = assert_raises(Reservations::RuleCheck::Violation) { book }
    assert_equal :inactive_area, error.key
  end
end
