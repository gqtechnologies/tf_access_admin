# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsColumnMapperTest < ActiveSupport::TestCase
    test "maps owner fields from template headers" do
      headers = %w[
        unit_identifier
        unit_type
        status
        area_m2
        owner_first_name
        owner_last_name
        owner_document
        owner_email
        ownership_percentage
      ]

      mappings = UnitsColumnMapper.call(headers:)
      by_target = mappings.index_by { |mapping| mapping["target"] }

      assert_equal "owner_document", by_target["owner_document"]["source"]
      assert_equal "owner_email", by_target["owner_email"]["source"]
      assert_equal "owner_first_name", by_target["owner_first_name"]["source"]
      assert_equal "owner_last_name", by_target["owner_last_name"]["source"]
      assert_equal "ownership_percentage", by_target["ownership_percentage"]["source"]
      assert by_target["owner_document"]["matched"]
      assert by_target["ownership_percentage"]["matched"]
    end
  end
end
