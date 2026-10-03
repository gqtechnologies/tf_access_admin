# frozen_string_literal: true

module Reservations
  # Checks a requested slot against the area's state and rules, in the
  # property's time zone. Raises Violation with an i18n key under
  # api.reservations.rules and its interpolation values.
  class RuleCheck
    class Violation < StandardError
      attr_reader :key, :values

      def initialize(key, values = {})
        @key = key
        @values = values
        super(key)
      end

      def message_text
        I18n.t("api.reservations.rules.#{key}", **values)
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(area:, unit:, starts_at:, ends_at:, guest_count: 0, now: Time.zone.now)
      @area = area
      @unit = unit
      @zone = area.time_zone
      @starts_at = starts_at&.in_time_zone(@zone)
      @ends_at = ends_at&.in_time_zone(@zone)
      @guest_count = guest_count.to_i
      @now = now
      @rules = area.rules
    end

    def call
      raise Violation, :inactive_area unless @area.active?
      raise Violation, :invalid_range if @starts_at.nil? || @ends_at.nil? || @ends_at <= @starts_at
      raise Violation, :in_the_past if @starts_at <= @now

      check_capacity
      check_advance
      check_duration
      check_opening_hours
      check_monthly_limit
      true
    end

    private

    def check_capacity
      return if @area.capacity.blank? || @guest_count <= @area.capacity

      raise Violation.new(:capacity, count: @area.capacity)
    end

    def check_advance
      hours = rule(CommonAreaRule::RULE_MIN_ADVANCE_HOURS)
      return if hours.blank? || @starts_at >= @now + hours.to_i.hours

      raise Violation.new(:min_advance, count: hours.to_i)
    end

    def check_duration
      minutes = rule(CommonAreaRule::RULE_MAX_DURATION_MINUTES)
      return if minutes.blank? || (@ends_at - @starts_at) <= minutes.to_i.minutes

      raise Violation.new(:max_duration, count: minutes.to_i)
    end

    # The slot must sit inside opens_at..closes_at of the start's local day
    # (closes_at defaults to midnight, so a booking never spans two days).
    def check_opening_hours
      opens = rule(CommonAreaRule::RULE_OPENS_AT)
      closes = rule(CommonAreaRule::RULE_CLOSES_AT)
      return if opens.blank? && closes.blank?

      raise Violation.new(:opening_hours, opens: opens || "00:00", closes: closes || "24:00") unless within_hours?(opens, closes)
    end

    def within_hours?(opens, closes)
      day = @starts_at.beginning_of_day
      opens_at = opens.present? ? day + minutes_of(opens).minutes : day
      closes_at = closes.present? ? day + minutes_of(closes).minutes : day + 1.day

      @starts_at >= opens_at && @ends_at <= closes_at
    end

    def check_monthly_limit
      limit = rule(CommonAreaRule::RULE_MAX_RESERVATIONS_MONTH)
      return if limit.blank?

      month = @starts_at.all_month
      count = @area.common_area_reservations.holding_slot.where(unit_id: @unit.id, starts_at: month).count
      return if count < limit.to_i

      raise Violation.new(:monthly_limit, count: limit.to_i)
    end

    def rule(type)
      @rules[type]
    end

    def minutes_of(hhmm)
      hours, minutes = hhmm.to_s.split(":").map(&:to_i)
      (hours * 60) + minutes.to_i
    end
  end
end
