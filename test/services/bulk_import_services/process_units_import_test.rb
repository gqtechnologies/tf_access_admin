# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class ProcessUnitsImportTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Import Property",
        property_type: "building",
        status: "active",
        country: "Chile",
        timezone: "America/Santiago"
      )
      @bulk_import = BulkImport.create!(
        organization: @organization,
        created_by: @user,
        residential_property: @property,
        import_type: BulkImport::IMPORT_TYPES[:units],
        status: "processing",
        metadata: {
          "import_execution" => { "import_valid_rows_only" => true }
        }
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "importable_scope with import_valid_rows_only excludes errors and duplicates" do
      create_row!(validation_status: "valid")
      create_row!(validation_status: "warning")
      create_row!(validation_status: "duplicate")
      create_row!(validation_status: "error")

      scope = ProcessUnitsImport.importable_scope(
        bulk_import: @bulk_import,
        import_valid_rows_only: true
      )

      assert_equal 2, scope.count
      assert scope.where(validation_status: "valid").exists?
      assert scope.where(validation_status: "warning").exists?
      assert_not scope.where(validation_status: "error").exists?
      assert_not scope.where(validation_status: "duplicate").exists?
    end

    test "importable_scope without import_valid_rows_only still excludes errors" do
      @bulk_import.update!(
        metadata: { "import_execution" => { "import_valid_rows_only" => false } }
      )

      create_row!(validation_status: "valid")
      create_row!(validation_status: "error")
      create_row!(validation_status: "duplicate", import_status: "pending")

      scope = ProcessUnitsImport.importable_scope(
        bulk_import: @bulk_import,
        import_valid_rows_only: false
      )

      assert_equal 2, scope.count
      assert_not scope.where(validation_status: "error").exists?
      assert scope.where(validation_status: "duplicate").exists?
    end

    private

    def create_row!(validation_status:, import_status: "pending")
      @bulk_import.rows.create!(
        row_number: @bulk_import.rows.count + 1,
        raw_payload: {},
        normalized_payload: { "unit_identifier" => "U#{@bulk_import.rows.count + 1}" },
        validation_status: validation_status,
        import_status: import_status,
        validation_errors: [],
        validation_warnings: []
      )
    end
  end
end
