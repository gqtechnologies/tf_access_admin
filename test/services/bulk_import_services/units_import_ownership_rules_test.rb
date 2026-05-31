# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportOwnershipRulesTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @property = ResidentialProperty.create!(
        organization: @organization,
        name: "Ownership Rules Property",
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
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    test "will_import_ownership is false for duplicate units in create mode" do
      Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "102",
        unit_type: "apartment"
      )

      bulk_import = build_bulk_import("create_skip_duplicates")
      context = UnitsImportValidationContext.new(bulk_import:)
      normalized = owner_payload("102")

      assert_not UnitsImportOwnershipRules.will_import_ownership?(
        context:,
        normalized:,
        row_errors: []
      )
    end

    test "will_import_ownership is true for new units in create mode" do
      bulk_import = build_bulk_import("create_skip_duplicates")
      context = UnitsImportValidationContext.new(bulk_import:)
      normalized = owner_payload("103")

      assert UnitsImportOwnershipRules.will_import_ownership?(
        context:,
        normalized:,
        row_errors: []
      )
    end

    test "validation flags duplicate existing units without ownership percentage error" do
      Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "102",
        unit_type: "apartment"
      )
      person = Person.create!(
        organization: @organization,
        display_name: "Existing Owner",
        person_type: PersonTypes::NATURAL,
        status: "active"
      )
      unit = Unit.find_by!(normalized_identifier: "102", property_section: @section)
      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      bulk_import = build_bulk_import("create_skip_duplicates")
      result = validate_row(bulk_import, 2, "102")

      assert_equal false, result.normalized_payload["will_import_ownership"]
      assert_equal BulkImportRow::VALIDATION_STATUSES[:duplicate], result.validation_status

      context = UnitsImportValidationContext.new(bulk_import:)
      ValidateUnitsImport.new(bulk_import:).send(:apply_group_percentage_errors!, [ result ], context)

      assert_not result.validation_errors.any? { |error| error["code"] == "ownership_percentage_sum_exceeded" }
    end

    test "two co-owner rows for a new unit exceed ownership cap at validation" do
      bulk_import = build_bulk_import("create_skip_duplicates")
      context = UnitsImportValidationContext.new(bulk_import:)
      results = [
        validate_row(bulk_import, 2, "104", context:, document: "111", email: "a@example.com"),
        validate_row(bulk_import, 3, "104", context:, document: "222", email: "b@example.com")
      ]

      assert results.all? { |result| result.normalized_payload["will_import_ownership"] }

      ValidateUnitsImport.new(bulk_import:).send(:apply_group_percentage_errors!, results, context)

      assert results.all? { |result| result.validation_status == BulkImportRow::VALIDATION_STATUSES[:error] }
    end

    test "load_existing_group_percentages ignores soft-deleted and inactive owners" do
      unit = Unit.create!(
        organization: @organization,
        residential_property: @property,
        property_section: @section,
        identifier: "102",
        unit_type: "apartment"
      )
      active_person = Person.create!(
        organization: @organization,
        display_name: "Active Owner",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      deleted_person = Person.create!(
        organization: @organization,
        display_name: "Deleted Owner",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      inactive_person = Person.create!(
        organization: @organization,
        display_name: "Inactive Owner",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::INACTIVE
      )

      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: deleted_person,
        ownership_percentage: 60,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: inactive_person,
        ownership_percentage: 40,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
      deleted_person.destroy

      bulk_import = build_bulk_import("update_only")
      context = UnitsImportValidationContext.new(bulk_import:)
      key = context.build_group_key(@section.id, unit.identifier)
      percentages = context.instance_variable_get(:@group_percentages)

      assert_equal 0.0, percentages.fetch(key, 0.0)

      UnitOwnership.create!(
        organization: @organization,
        unit: unit,
        person: active_person,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )

      context = UnitsImportValidationContext.new(bulk_import:)
      percentages = context.instance_variable_get(:@group_percentages)

      assert_equal 100.0, percentages.fetch(key)
    end

    private

    def owner_payload(unit_identifier, document: "11111111-1", email: "owner@example.com")
      {
        "unit_identifier" => unit_identifier,
        "unit_type" => "apartment",
        "owner_document" => document,
        "owner_email" => email,
        "owner_first_name" => "Juan",
        "owner_last_name" => "Perez"
      }
    end

    def validate_row(bulk_import, row_number, unit_identifier, context: nil, document: "11111111-1", email: "owner@example.com")
      context ||= UnitsImportValidationContext.new(bulk_import:)
      parsed_row = UnitsSpreadsheetReader::ParsedRow.new(
        row_number: row_number,
        raw_payload: owner_payload(unit_identifier, document:, email:)
      )
      UnitsImportRowValidator.call(parsed_row:, context:)
    end

    def build_bulk_import(import_mode)
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
