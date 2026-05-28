# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class BulkImportReportTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Report Property",
        property_type: "building",
        status: "active",
        country: "Chile",
        timezone: "America/Santiago"
      )
      @bulk_import = BulkImport.create!(
        organization: @organization,
        created_by: @user,
        residential_property: @property,
        import_type: BulkImport::IMPORT_TYPES[:units]
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "generates UTF-8 BOM CSV with extended columns" do
      @bulk_import.rows.create!(
        row_number: 1,
        raw_payload: {},
        normalized_payload: {
          "unit_identifier" => "101",
          "property_section_id" => "section-uuid",
          "owner_document" => "12345678",
          "owner_email" => "owner@example.com"
        },
        validation_status: "valid",
        import_status: "imported",
        validation_errors: [],
        validation_warnings: []
      )

      csv = BulkImportReport.call(bulk_import: @bulk_import)

      assert csv.start_with?("\uFEFF")
      assert_includes csv, "unit_identifier"
      assert_includes csv, "owner_document"
      assert_includes csv, "101"
      assert_includes csv, "owner@example.com"
    end

    test "handles missing normalized payload fields" do
      @bulk_import.rows.create!(
        row_number: 2,
        raw_payload: {},
        normalized_payload: {},
        validation_status: "error",
        import_status: "pending",
        validation_errors: [ { "field" => "unit_identifier", "code" => "missing", "message" => "Missing unit" } ],
        validation_warnings: []
      )

      csv = BulkImportReport.call(bulk_import: @bulk_import)

      assert_includes csv, "Missing unit"
    end
  end
end
