# frozen_string_literal: true

module BulkImportServices
  class FileInspector
    Result = Struct.new(:sheets, :selected_sheet, :headers, :row_count, :error, keyword_init: true)

    EXTENSION_BY_CONTENT_TYPE = {
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => :xlsx,
      "application/vnd.ms-excel" => :xls,
      "text/csv" => :csv
    }.freeze

    def self.call(file_path:, filename:, content_type: nil, selected_sheet: nil)
      new(file_path:, filename:, content_type:, selected_sheet:).call
    end

    def initialize(file_path:, filename:, content_type: nil, selected_sheet: nil)
      @file_path = file_path
      @filename = filename
      @content_type = content_type
      @selected_sheet = selected_sheet
    end

    def call
      spreadsheet = Roo::Spreadsheet.open(@file_path, extension: extension)
      sheets = spreadsheet.sheets
      return empty_result(error: "no_sheets") if sheets.blank?

      if @selected_sheet.present? && !sheets.include?(@selected_sheet)
        return Result.new(sheets: sheets, selected_sheet: nil, headers: [], row_count: 0, error: "sheet_not_found")
      end

      selected_sheet = @selected_sheet.presence || sheets.first
      sheet = spreadsheet.sheet(selected_sheet)
      first_row = sheet.row(1).map { |cell| cell.to_s.strip }
      headers = first_row.reject(&:blank?)
      row_count = [ sheet.last_row - 1, 0 ].max

      Result.new(
        sheets: sheets,
        selected_sheet: selected_sheet,
        headers: headers,
        row_count: row_count,
        error: nil
      )
    rescue StandardError => e
      Rails.logger.warn("[BulkImportServices::FileInspector] #{e.class}: #{e.message}")
      empty_result(error: "parse_failed")
    end

    private

    def extension
      from_content_type = EXTENSION_BY_CONTENT_TYPE[@content_type]
      return from_content_type if from_content_type

      ext = File.extname(@filename).delete_prefix(".").downcase.to_sym
      return ext if %i[xlsx xls csv].include?(ext)

      :xlsx
    end

    def empty_result(error:)
      Result.new(sheets: [], selected_sheet: nil, headers: [], row_count: 0, error: error)
    end
  end
end
