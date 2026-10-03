# frozen_string_literal: true

module Reservations
  # A resident books a common area for their unit. Needs a currently valid
  # occupancy of that unit with can_reserve_common_areas; the slot must pass the
  # area's rules and be free. Areas that require approval leave it pending for
  # the administration; the rest are approved on the spot.
  class Request
    class NotEligible < StandardError; end
    class SlotTaken < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.eligible?(person:, unit:)
      return false if person.blank? || unit.blank?

      Authorization::ActiveRelationships.active_occupancies_of_unit(unit)
                                        .where(person_id: person.id, can_reserve_common_areas: true)
                                        .exists?
    end

    def initialize(area:, unit:, person:, starts_at:, ends_at:, guest_count: 0)
      @area = area
      @unit = unit
      @person = person
      @starts_at = starts_at
      @ends_at = ends_at
      @guest_count = guest_count.to_i
    end

    def call
      raise NotEligible unless @unit.residential_property_id == @area.residential_property_id
      raise NotEligible unless self.class.eligible?(person: @person, unit: @unit)

      RuleCheck.call(area: @area, unit: @unit, starts_at: @starts_at, ends_at: @ends_at, guest_count: @guest_count)

      auto_approve = !@area.requires_approval?
      reservation = nil

      ActiveRecord::Base.transaction do
        reservation = CommonAreaReservation.create!(
          organization: @area.organization,
          common_area: @area,
          residential_property: @area.residential_property,
          unit: @unit,
          requested_by_person: @person,
          starts_at: @starts_at,
          ends_at: @ends_at,
          guest_count: @guest_count,
          status: auto_approve ? ReservationStatuses::APPROVED : ReservationStatuses::PENDING,
          approved_at: auto_approve ? Time.zone.now : nil
        )
        reservation.common_area_reservation_status_histories.create!(
          organization: reservation.organization,
          from_status: nil,
          to_status: reservation.status,
          changed_by_person: @person
        )
      end

      reservation
    rescue ActiveRecord::StatementInvalid => e
      # common_area_reservations_no_overlap: another pending/approved booking holds the slot.
      raise SlotTaken if e.message.include?("common_area_reservations_no_overlap")

      raise
    end
  end
end
