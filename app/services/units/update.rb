# frozen_string_literal: true

module Units
  # Applies descriptive changes and operational status transitions
  # (improve-units-foundation §2.3).
  class Update < Base
    def initialize(actor:, unit:, attributes: {})
      super(actor: actor)
      @unit       = unit
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      authorize_manage_units!(@unit.residential_property)

      return Result.invalid(@unit) unless reject_inoperative_property!(@unit)

      @unit.assign_attributes(descriptive_attributes(@attributes))
      return Result.invalid(@unit) if archive_via_status_requested?
      return Result.invalid(@unit) if invalid_status_transition?

      apply_status

      save_unit(@unit)
    end

    private

    def archive_via_status_requested?
      return false unless @attributes.key?(:status)
      return false unless @attributes[:status].to_s.strip.downcase == UnitStatuses::ARCHIVED

      @unit.errors.add(:status, :archive_requires_service)
      true
    end

    def invalid_status_transition?
      return false unless @attributes.key?(:status)

      requested = @attributes[:status].to_s.strip.downcase.presence
      return false if requested.nil?
      return false if UnitStatuses::OPERATIONAL.include?(requested)

      @unit.errors.add(:status, :transition_not_allowed)
      true
    end

    def apply_status
      return unless @attributes.key?(:status)

      requested = @attributes[:status].to_s.strip.downcase.presence
      @unit.status = requested if requested
    end
  end
end
