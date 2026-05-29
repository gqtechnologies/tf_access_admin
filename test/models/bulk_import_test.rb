# frozen_string_literal: true

# == Schema Information
#
# Table name: bulk_imports
#
#  id                      :uuid             not null, primary key
#  cancelled_at            :datetime
#  confirmed_at            :datetime
#  content_type            :string
#  error_rows              :integer          default(0), not null
#  expires_at              :datetime
#  failed_rows             :integer          default(0), not null
#  failure_message         :text
#  file_checksum           :string
#  file_size               :bigint
#  finished_at             :datetime
#  import_type             :string           not null
#  imported_rows           :integer          default(0), not null
#  metadata                :jsonb            not null
#  original_filename       :string
#  processing_started_at   :datetime
#  skipped_rows            :integer          default(0), not null
#  status                  :string           default("draft"), not null
#  summary                 :jsonb            not null
#  total_rows              :integer          default(0), not null
#  valid_rows              :integer          default(0), not null
#  validated_at            :datetime
#  warning_rows            :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  created_by_id           :uuid             not null
#  organization_id         :uuid             not null
#  property_section_id     :uuid
#  residential_property_id :uuid
#
# Indexes
#
#  index_bulk_imports_on_created_at                       (created_at)
#  index_bulk_imports_on_created_by_id                    (created_by_id)
#  index_bulk_imports_on_expires_at                       (expires_at)
#  index_bulk_imports_on_file_checksum                    (file_checksum)
#  index_bulk_imports_on_import_type                      (import_type)
#  index_bulk_imports_on_metadata                         (metadata) USING gin
#  index_bulk_imports_on_organization_id                  (organization_id)
#  index_bulk_imports_on_organization_id_and_created_at   (organization_id,created_at)
#  index_bulk_imports_on_organization_id_and_import_type  (organization_id,import_type)
#  index_bulk_imports_on_organization_id_and_status       (organization_id,status)
#  index_bulk_imports_on_property_section_id              (property_section_id)
#  index_bulk_imports_on_residential_property_id          (residential_property_id)
#  index_bulk_imports_on_status                           (status)
#  index_bulk_imports_on_summary                          (summary) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (organization_id => organizations.id)
#  fk_rails_...  (property_section_id => property_sections.id)
#  fk_rails_...  (residential_property_id => residential_properties.id)
#
require "test_helper"

class BulkImportTest < ActiveSupport::TestCase
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
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "creates a valid bulk import in draft state" do
    bulk_import = BulkImport.new(
      organization: @organization,
      created_by: @user,
      residential_property: @property,
      import_type: BulkImport::IMPORT_TYPES[:units]
    )

    assert bulk_import.save
    assert bulk_import.draft?
    assert_equal "draft", bulk_import.status
  end

  test "rejects invalid import_type" do
    bulk_import = BulkImport.new(
      organization: @organization,
      created_by: @user,
      import_type: "invalid_type"
    )

    assert_not bulk_import.valid?
    assert_includes bulk_import.errors[:import_type], "is not included in the list"
  end

  test "AASM transitions through validation and confirmation" do
    bulk_import = BulkImport.create!(
      organization: @organization,
      created_by: @user,
      residential_property: @property,
      import_type: BulkImport::IMPORT_TYPES[:units]
    )

    assert bulk_import.may_mark_as_uploaded?
    bulk_import.mark_as_uploaded!
    assert bulk_import.uploaded?

    bulk_import.start_validation!
    assert bulk_import.validating?

    bulk_import.complete_validation!
    assert bulk_import.validated?

    bulk_import.confirm!
    assert bulk_import.confirmed?
  end

  test "may restart validation from validated state" do
    bulk_import = BulkImport.create!(
      organization: @organization,
      created_by: @user,
      residential_property: @property,
      import_type: BulkImport::IMPORT_TYPES[:units],
      status: "validated"
    )

    assert bulk_import.may_start_validation?
    bulk_import.start_validation!
    assert bulk_import.validating?
  end

  test "progress_percentage reflects processed rows" do
    bulk_import = BulkImport.create!(
      organization: @organization,
      created_by: @user,
      import_type: BulkImport::IMPORT_TYPES[:units],
      total_rows: 10,
      imported_rows: 5,
      failed_rows: 2,
      skipped_rows: 1
    )

    assert_equal 80, bulk_import.progress_percentage
  end
end
