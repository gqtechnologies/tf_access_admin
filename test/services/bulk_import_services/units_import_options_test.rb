# frozen_string_literal: true

require "test_helper"

module BulkImportServices
  class UnitsImportOptionsTest < ActiveSupport::TestCase
    test "OwnerImportMode.resolve returns known modes" do
      assert_equal "link_existing", OwnerImportMode.resolve("link_existing")
    end

    test "OwnerImportMode.resolve falls back for unknown modes" do
      assert_equal OwnerImportMode::DEFAULT, OwnerImportMode.resolve("invalid")
      assert_equal OwnerImportMode::DEFAULT, OwnerImportMode.resolve(nil)
    end

    test "UnitsImportMode.resolve returns known modes" do
      assert_equal "update_only", UnitsImportMode.resolve("update_only")
    end

    test "UnitsImportMode.resolve falls back for unknown modes" do
      assert_equal UnitsImportMode::DEFAULT, UnitsImportMode.resolve("invalid")
    end
  end
end
