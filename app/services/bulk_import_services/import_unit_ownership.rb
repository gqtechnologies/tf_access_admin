# frozen_string_literal: true

module BulkImportServices
  class ImportUnitOwnership
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(unit:, person:, row:)
      @unit = unit
      @person = person
      @row = row
      @payload = row.normalized_payload.deep_stringify_keys
    end

    def call
      percentage = ownership_percentage
      existing = UnitOwnership.find_by(
        unit_id: @unit.id,
        person_id: @person.id,
        organization_id: @unit.organization_id,
        status: UnitOwnership::STATUS_ACTIVE
      )
      return existing if existing

      UnitOwnership.create!(
        organization: @unit.organization,
        unit: @unit,
        person: @person,
        ownership_percentage: percentage,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
    end

    private

    def ownership_percentage
      value = @payload["ownership_percentage"].presence || 100
      Float(value).clamp(0, 100)
    rescue ArgumentError, TypeError
      100.0
    end
  end
end
