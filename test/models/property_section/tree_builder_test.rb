# frozen_string_literal: true

require "test_helper"

class PropertySection::TreeBuilderTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Tree Property",
      property_type: "building",
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )
    @tower = PropertySection.create!(
      organization: @organization,
      residential_property: @property,
      name: "Torre A",
      section_type: "tower"
    )
    @floor = PropertySection.create!(
      organization: @organization,
      residential_property: @property,
      parent: @tower,
      name: "Piso 1",
      section_type: "floor"
    )
    @unit = Unit.create!(
      organization: @organization,
      residential_property: @property,
      property_section: @floor,
      identifier: "101",
      unit_type: "apartment"
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "includes units on leaf sections only" do
    sections = PropertySection.where(residential_property: @property).includes(:units)
    tree = PropertySection::TreeBuilder.new(sections).as_json

    tower = tree.find { |node| node[:id] == @tower.id }
    floor = tower[:children].find { |node| node[:id] == @floor.id }

    assert_empty tower[:units]
    assert_equal 1, floor[:units].length
    assert_equal @unit.id, floor[:units].first[:id]
    assert_equal "101", floor[:units].first[:identifier]
  end
end
