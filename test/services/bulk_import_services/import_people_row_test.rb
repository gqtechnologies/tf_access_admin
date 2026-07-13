# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class ImportPeopleRowTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      @user = users(:one)
      @bulk_import = BulkImport.create!(
        organization: @organization,
        created_by: @user,
        import_type: BulkImport::IMPORT_TYPES[:users],
        status: "processing"
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
    end

    def build_row(payload, validation_status: BulkImportRow::VALIDATION_STATUSES[:valid])
      @bulk_import.rows.create!(
        row_number: 1,
        raw_payload: payload,
        normalized_payload: payload,
        validation_status: validation_status,
        import_status: BulkImportRow::IMPORT_STATUSES[:pending]
      )
    end

    test "creates an active natural person and an accepted organization membership" do
      row = build_row({
        "first_name" => "Ana",
        "last_name" => "Torres",
        "document_number" => "12345678",
        "phone" => "+56911112222",
        "email" => "ana.torres@example.test",
        "birthdate" => "1990-06-15"
      })

      result = ImportPeopleRow.call(row:, bulk_import: @bulk_import)

      assert_equal :imported, result
      row.reload
      assert_equal BulkImportRow::IMPORT_STATUSES[:imported], row.import_status

      person = row.target_record
      assert_instance_of Person, person
      assert_equal PersonStatuses::ACTIVE, person.status
      assert_equal PersonTypes::NATURAL, person.person_type
      assert Date.parse("1990-06-15") == person.birthdate

      membership = person.organization_membership
      assert membership.present?
      assert_equal OrganizationMembership::STATUS_ACTIVE, membership.status
      assert membership.joined_at.present?
    end

    test "skips a row already marked duplicate" do
      row = build_row(
        { "first_name" => "Ana", "last_name" => "Torres" },
        validation_status: BulkImportRow::VALIDATION_STATUSES[:duplicate]
      )
      row.update!(import_status: BulkImportRow::IMPORT_STATUSES[:pending])

      result = ImportPeopleRow.call(row:, bulk_import: @bulk_import)

      assert_equal :skipped, result
      assert_equal BulkImportRow::IMPORT_STATUSES[:skipped], row.reload.import_status
    end

    test "does not assign a role or unit assignment" do
      row = build_row({
        "first_name" => "Ana",
        "last_name" => "Torres",
        "document_number" => "33334444",
        "phone" => "+56911112222",
        "email" => "no-role@example.test",
        "birthdate" => "1990-06-15"
      })

      ImportPeopleRow.call(row:, bulk_import: @bulk_import)
      person = row.reload.target_record

      assert_empty person.roles
      assert_empty person.unit_ownerships
      assert_empty person.staff_assignments
    end
  end
end
