# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportOwnershipPercentageTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Ownership Percentage Property",
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
      @bulk_import = build_bulk_import
      @context = UnitsImportValidationContext.new(bulk_import: @bulk_import)
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "two co-owner rows without explicit percentages exceed cap at validation" do
      results = [
        validate_row(2, "101", "11111111-1", "owner1@example.com"),
        validate_row(3, "101", "22222222-2", "owner2@example.com")
      ]

      ValidateUnitsImport.new(bulk_import: @bulk_import).send(:apply_group_percentage_errors!, results, @context)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[0].validation_status
      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[1].validation_status
      assert_equal "ownership_percentage_sum_exceeded", results[0].validation_errors.last["code"]
    end

    test "includes existing active ownership when validating percentages in update_only mode" do
      unit = Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "101",
        unit_type: "apartment"
      )
      person = Person.create!(
        organization: @organization,
        display_name: "Existing Owner",
        person_type: PersonTypes::NATURAL,
        status: "active"
      )
      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      bulk_import = build_bulk_import(import_mode: "update_only")
      context = UnitsImportValidationContext.new(bulk_import:)
      results = [ validate_row(2, "101", "33333333-3", "newowner@example.com", context:) ]

      ValidateUnitsImport.new(bulk_import:).send(:apply_group_percentage_errors!, results, context)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[0].validation_status
    end

    test "does not exceed ownership cap for duplicate units in create_skip_duplicates mode" do
      unit = Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "101",
        unit_type: "apartment"
      )
      person = Person.create!(
        organization: @organization,
        display_name: "Existing Owner",
        person_type: PersonTypes::NATURAL,
        status: "active"
      )
      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      context = UnitsImportValidationContext.new(bulk_import: @bulk_import)
      results = [ validate_row(2, "101", "33333333-3", "newowner@example.com", context:) ]

      ValidateUnitsImport.new(bulk_import: @bulk_import).send(:apply_group_percentage_errors!, results, context)

      assert_not_equal "ownership_percentage_sum_exceeded", results[0].validation_errors.last&.dig("code")
    end

    private

    def validate_row(row_number, unit_identifier, document, email, context: @context)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: row_number,
        raw_payload: {
          "unit_identifier" => unit_identifier,
          "unit_type" => "apartment",
          "owner_document" => document,
          "owner_email" => email,
          "owner_first_name" => "Juan",
          "owner_last_name" => "Perez"
        }
      )
      UnitsImportRowValidator.call(parsed_row:, context:)
    end

    def build_bulk_import(import_mode: "create_skip_duplicates")
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
            "owner_import_mode" => "create_missing"
          },
          "file_inspection" => { "sheets" => [], "headers" => [], "row_count" => 0 }
        }
      )
    end
  end
end
