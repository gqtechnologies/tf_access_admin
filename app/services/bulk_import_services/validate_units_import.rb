# frozen_string_literal: true

module BulkImportServices
  class ValidateUnitsImport
    VALIDATABLE_STATUSES = %w[uploaded validated validation_failed].freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(bulk_import:)
      @bulk_import = bulk_import
    end

    def call
      ensure_validatable!

      @bulk_import.start_validation! if @bulk_import.may_start_validation?
      @bulk_import.rows.destroy_all

      context = UnitsImportValidationContext.new(bulk_import: @bulk_import)
      parsed_rows = UnitsSpreadsheetReader.call(bulk_import: @bulk_import)
      results = parsed_rows.map do |parsed_row|
        UnitsImportRowValidator.call(parsed_row:, context:)
      end

      apply_group_percentage_errors!(results, context)

      BulkImportRow.transaction do
        results.each { |result| create_row!(result) }
      end

      refresh_counters!
      transition_validation_status!
      @bulk_import.touch
      @bulk_import
    end

    private

    def ensure_validatable!
      return if VALIDATABLE_STATUSES.include?(@bulk_import.status)

      @bulk_import.errors.add(:status, :invalid)
      raise ActiveRecord::RecordInvalid, @bulk_import
    end

    def apply_group_percentage_errors!(results, context)
      results.each do |result|
        group_key = result.group_key
        next if group_key.blank?
        next unless context.group_percentage_exceeded?(group_key)

        result.validation_errors << {
          "field" => "ownership_percentage",
          "code" => "ownership_percentage_sum_exceeded",
          "message" => I18n.t("frontend.admin.bulk_imports.validation.ownership_percentage_sum_exceeded")
        }
        result.validation_status = BulkImportRow::VALIDATION_STATUSES[:error]
        result.import_status = BulkImportRow::IMPORT_STATUSES[:pending]
      end
    end

    def create_row!(result)
      @bulk_import.rows.create!(
        row_number: result.row_number,
        raw_payload: result.raw_payload,
        normalized_payload: result.normalized_payload,
        validation_status: result.validation_status,
        import_status: result.import_status,
        validation_errors: result.validation_errors,
        validation_warnings: result.validation_warnings,
        group_key: result.group_key,
        validated_at: Time.current
      )
    end

    def refresh_counters!
      rows = @bulk_import.rows.reload
      @bulk_import.update!(
        total_rows: rows.count,
        valid_rows: rows.where(validation_status: BulkImportRow::VALIDATION_STATUSES[:valid]).count,
        warning_rows: rows.where(validation_status: BulkImportRow::VALIDATION_STATUSES[:warning]).count,
        error_rows: rows.where(validation_status: BulkImportRow::VALIDATION_STATUSES[:error]).count,
        skipped_rows: rows.where(import_status: BulkImportRow::IMPORT_STATUSES[:skipped]).count,
        validated_at: Time.current
      )
    end

    def transition_validation_status!
      if @bulk_import.error_rows.positive?
        @bulk_import.fail_validation! if @bulk_import.may_fail_validation?
      elsif @bulk_import.may_complete_validation?
        @bulk_import.complete_validation!
      end
    end
  end
end
