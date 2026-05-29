# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportRowValidatorImportModeTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Import Mode Property",
        property_type: "building",
        status: "active",
        country: "Chile",
        timezone: "America/Santiago"
      )
      @section = PropertySection.create!(
        organization: @organization,
        residential_property: @property,
        name: "Piso 1",
        section_type: "floor"
      )
      @existing_unit = Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "101",
        unit_type: "apartment"
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "update_only marks existing unit as valid with target_unit_id" do
      bulk_import = build_bulk_import(import_mode: "update_only")
      context = UnitsImportValidationContext.new(bulk_import:)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: 2,
        raw_payload: {
          "unit_identifier" => "101",
          "unit_type" => "apartment",
          "status" => "occupied"
        }
      )

      result = UnitsImportRowValidator.call(parsed_row:, context:)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:valid], result.validation_status
      assert_empty result.validation_errors
      assert_equal @existing_unit.id, result.normalized_payload["target_unit_id"]
      assert_equal "update", result.normalized_payload["operation"]
    end

    test "update_only errors when unit does not exist" do
      bulk_import = build_bulk_import(import_mode: "update_only")
      context = UnitsImportValidationContext.new(bulk_import:)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: 3,
        raw_payload: {
          "unit_identifier" => "999",
          "unit_type" => "apartment"
        }
      )

      result = UnitsImportRowValidator.call(parsed_row:, context:)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], result.validation_status
      assert_equal "unit_not_found_for_update", result.validation_errors.first["code"]
    end

    test "create_only errors when unit already exists" do
      bulk_import = build_bulk_import(import_mode: "create_only")
      context = UnitsImportValidationContext.new(bulk_import:)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: 4,
        raw_payload: {
          "unit_identifier" => "101",
          "unit_type" => "apartment"
        }
      )

      result = UnitsImportRowValidator.call(parsed_row:, context:)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], result.validation_status
      assert_equal "duplicate_in_database", result.validation_errors.first["code"]
    end

    test "create_skip_duplicates warns when unit already exists" do
      bulk_import = build_bulk_import(import_mode: "create_skip_duplicates")
      context = UnitsImportValidationContext.new(bulk_import:)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: 5,
        raw_payload: {
          "unit_identifier" => "101",
          "unit_type" => "apartment"
        }
      )

      result = UnitsImportRowValidator.call(parsed_row:, context:)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:duplicate], result.validation_status
      assert_equal "duplicate_in_database", result.validation_warnings.first["code"]
    end

    private

    def build_bulk_import(import_mode:)
      BulkImport.create!(
        organization: @organization,
        created_by: @user,
        residential_property: @property,
        property_section: @section,
        import_type: BulkImport::IMPORT_TYPES[:units],
        metadata: {
          "options" => {
            "import_mode" => import_mode,
            "property_section_id" => @section.id,
            "owner_import_mode" => "ignore"
          },
          "file_inspection" => { "sheets" => [], "headers" => [], "row_count" => 0 }
        }
      )
    end
  end
end
