# frozen_string_literal: true

module BulkImportServices
  class ImportUnitsRow
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(row:, bulk_import:)
      @row = row
      @bulk_import = bulk_import
      @payload = row.normalized_payload.deep_stringify_keys
    end

    def call
      return skip_duplicate! if duplicate_row?
      return skip_pending! if @row.import_status == BulkImportRow::IMPORT_STATUSES[:skipped]

      unit = create_unit!
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
