# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportRowValidatorTest < ActiveSupport::TestCase
    test "splits owner_name into first and last name when parts are missing" do
      validator = UnitsImportRowValidator.new(
        parsed_row: UnitsSpreadsheetReader::ParsedRow.new(
          row_number: 1,
          raw_payload: { "owner_name" => "Juan Perez" }
        ),
        context: nil
      )

      normalized = validator.send(:normalize_payload, { "owner_name" => "Juan Perez" })

      assert_equal "Juan", normalized["owner_first_name"]
      assert_equal "Perez", normalized["owner_last_name"]
    end

    test "does not overwrite existing owner first and last names" do
      validator = UnitsImportRowValidator.new(
        parsed_row: UnitsSpreadsheetReader::ParsedRow.new(row_number: 1, raw_payload: {}),
        context: nil
      )

      normalized = validator.send(
        :normalize_payload,
        {
          "owner_name" => "Juan Perez",
          "owner_first_name" => "Maria",
          "owner_last_name" => "Gonzalez"
        }
      )

      assert_equal "Maria", normalized["owner_first_name"]
      assert_equal "Gonzalez", normalized["owner_last_name"]
    end
  end
end
