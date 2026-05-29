# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportOwnerIdentityTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Owner Identity Property",
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

    test "same document with different emails is an error" do
      results = [
        validate_row(2, "111", "a@example.com"),
        validate_row(3, "111", "b@example.com")
      ]

      @context.apply_owner_identity_conflicts!(results)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[0].validation_status
      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[1].validation_status
      assert_equal "owner_document_email_conflict", results[0].validation_errors.last["code"]
    end

    test "same email with different documents is an error" do
      results = [
        validate_row(2, "111", "owner@example.com"),
        validate_row(3, "222", "owner@example.com")
      ]

      @context.apply_owner_identity_conflicts!(results)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[0].validation_status
      assert_equal BulkImportRow::VALIDATION_STATUSES[:error], results[1].validation_status
      assert_equal "owner_email_document_conflict", results[0].validation_errors.last["code"]
    end

    test "consistent document and email passes identity checks" do
      results = [
        validate_row(2, "111", "owner@example.com"),
        validate_row(3, "111", "owner@example.com")
      ]

      @context.apply_owner_identity_conflicts!(results)

      assert_equal BulkImportRow::VALIDATION_STATUSES[:valid], results[0].validation_status
      assert_equal BulkImportRow::VALIDATION_STATUSES[:valid], results[1].validation_status
    end

    private

    def validate_row(row_number, document, email)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: row_number,
        raw_payload: {
          "unit_identifier" => "U#{row_number}",
          "unit_type" => "apartment",
          "owner_document" => document,
          "owner_email" => email,
          "owner_first_name" => "Juan",
          "owner_last_name" => "Perez"
        }
      )
      UnitsImportRowValidator.call(parsed_row:, context: @context)
    end

    def build_bulk_import
      BulkImport.create!(
        organization: @organization,
        created_by: @user,
        residential_property: @property,
        property_section: @section,
        import_type: BulkImport::IMPORT_TYPES[:units],
        metadata: {
          "options" => {
            "import_mode" => "create_skip_duplicates",
            "property_section_id" => @section.id,
            "owner_import_mode" => "link_existing"
          },
          "file_inspection" => { "sheets" => [], "headers" => [], "row_count" => 0 }
        }
      )
    end
  end
end
