# frozen_string_literal: true

require "ostruct"
require "test_helper"

class PropertySection::BreadcrumbPathTest < ActiveSupport::TestCase
  test "build returns ancestor names from root to section" do
    root = OpenStruct.new(id: "r1", name: "Torre A", parent_id: nil)
    floor = OpenStruct.new(id: "f1", name: "Piso 1", parent_id: "r1")
    sections_by_id = { "r1" => root, "f1" => floor }

    assert_equal [ "Torre A", "Piso 1" ], PropertySection::BreadcrumbPath.build(floor, sections_by_id: sections_by_id)
  end

  test "build returns empty array when section is nil" do
    assert_equal [], PropertySection::BreadcrumbPath.build(nil, sections_by_id: {})
  end
end
