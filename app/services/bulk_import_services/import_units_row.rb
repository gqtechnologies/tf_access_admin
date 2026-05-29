# frozen_string_literal: true

module BulkImportServices
  class ImportUnitsRow
    include UnitsImportMode

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(row:, bulk_import:, import_context: nil)
      @row = row
      @bulk_import = bulk_import
      @import_context = import_context || ImportUnitsImportContext.new(bulk_import:)
      @payload = row.normalized_payload.deep_stringify_keys
      options = @bulk_import.metadata.fetch("options", {})
      @import_mode = UnitsImportMode.resolve(options["import_mode"])
    end

    def call
      return update_unit! if update_only?

      return skip_duplicate! if duplicate_row?
      return skip_pending! if @row.import_status == BulkImportRow::IMPORT_STATUSES[:skipped]

      unit = nil
      ActiveRecord::Base.transaction do
        unit = create_unit!
        import_ownership!(unit)
      end
      mark_imported!(unit)
      :imported
    rescue ActiveRecord::RecordInvalid => e
      mark_failed!(e.record.errors.full_messages.join(", "))
      :failed
    rescue ActiveRecord::RecordNotUnique
      mark_skipped!(I18n.t("frontend.admin.bulk_imports.import.logs.duplicate_skipped"))
      :skipped
    rescue StandardError => e
      mark_failed!(e.message)
      :failed
    end

    def import_mode
      @import_mode
    end

    private

    def duplicate_row?
      @row.validation_status == BulkImportRow::VALIDATION_STATUSES[:duplicate]
    end

    def skip_duplicate!
      mark_skipped!(I18n.t("frontend.admin.bulk_imports.import.logs.duplicate_skipped"))
      :skipped
    end

    def skip_pending!
      mark_skipped!(I18n.t("frontend.admin.bulk_imports.import.logs.skipped"))
      :skipped
    end

    def update_unit!
      unit = resolve_unit_for_update
      if unit.nil?
        mark_failed!(I18n.t("frontend.admin.bulk_imports.validation.unit_not_found_for_update"))
        return :failed
      end

      ActiveRecord::Base.transaction do
        unit.update!(unit_attributes)
        import_ownership!(unit)
      end
      mark_imported!(unit)
      :imported
    rescue ActiveRecord::RecordInvalid => e
      mark_failed!(e.record.errors.full_messages.join(", "))
      :failed
    rescue StandardError => e
      mark_failed!(e.message)
      :failed
    end

    def import_ownership!(unit)
      return if @import_context.ignore_owners?
      return unless owner_data_present?

      person = @import_context.resolve_person!(@payload)
      if person.nil?
        raise StandardError, I18n.t("frontend.admin.bulk_imports.validation.owner_not_found")
      end

      ImportUnitOwnership.call(unit:, person:, row: @row)
    end

    def owner_data_present?
      @payload.values_at("owner_email", "owner_document").any?(&:present?)
    end

    def resolve_unit_for_update
      unit_id = @payload["target_unit_id"]
      if unit_id.present?
        return Unit.find_by(id: unit_id, organization_id: @bulk_import.organization_id)
      end

      section_id = @payload["property_section_id"].presence || @bulk_import.property_section_id
      normalized = AlphanumericHyphenCodeValidatable.normalize_identifier(@payload["unit_identifier"])
      return nil if section_id.blank? || normalized.blank?

      Unit.find_by(
        organization_id: @bulk_import.organization_id,
        residential_property_id: @bulk_import.residential_property_id,
        property_section_id: section_id,
        normalized_identifier: normalized
      )
    end

    def unit_attributes
      attrs = {
        unit_type: @payload["unit_type"].to_s.downcase,
        display_name: @payload["display_name"],
        area_m2: parse_area(@payload["area_m2"]),
        status: normalized_status
      }
      attrs.compact
    end

    def create_unit!
      section_id = @payload["property_section_id"].presence || @bulk_import.property_section_id

      Unit.create!(
        organization: @bulk_import.organization,
        residential_property: @bulk_import.residential_property,
        property_section_id: section_id,
        identifier: @payload["unit_identifier"],
        unit_type: @payload["unit_type"].to_s.downcase,
        display_name: @payload["display_name"],
        area_m2: parse_area(@payload["area_m2"]),
        status: normalized_status
      )
    end

    def normalized_status
      value = @payload["status"].to_s.strip.downcase.presence
      return value if value.present? && UnitStatuses::ALL.include?(value)

      "available"
    end

    def parse_area(value)
      return nil if value.blank?

      BigDecimal(value.to_s)
    rescue ArgumentError
      nil
    end

    def mark_imported!(unit)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:imported],
        imported_at: Time.current,
        target_record: unit,
        operation: update_only? ? "update" : "create",
        failure_message: nil
      )
    end

    def mark_skipped!(message)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:skipped],
        skipped_at: Time.current,
        failure_message: message
      )
    end

    def mark_failed!(message)
      @row.update!(
        import_status: BulkImportRow::IMPORT_STATUSES[:failed],
        failed_at: Time.current,
        failure_message: message
      )
    end
  end
end
