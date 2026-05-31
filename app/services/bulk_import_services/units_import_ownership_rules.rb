# frozen_string_literal: true

module BulkImportServices
  module UnitsImportOwnershipRules
    module_function

    def resolved_ownership_percentage(normalized)
      value = normalized["ownership_percentage"].presence || 100
      Float(value)
    rescue ArgumentError, TypeError
      100.0
    end

    def will_import_ownership?(context:, normalized:, row_errors: [])
      return false unless context.process_owners?
      return false if context.ignore_owners?
      return false unless context.owner_data_present?(normalized)
      return false if row_errors.any?

      existing_unit = context.find_existing_unit(
        context.property_section_id,
        normalized["unit_identifier"]
      )

      if context.update_only?
        existing_unit.present?
      else
        existing_unit.nil?
      end
    end
  end
end
