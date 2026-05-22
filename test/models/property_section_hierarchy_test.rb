# frozen_string_literal: true

require "test_helper"

class PropertySectionHierarchyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Test Property",
      property_type: "building",
      status: "active",
      country: "Chile",
      timezone: "America/Santiago"
    )

    @tower = @property.property_sections.create!(
      organization: @organization,
      name: "Torre A",
      section_type: "tower"
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "root section can have a child section" do
    floor = @property.property_sections.build(
      organization: @organization,
      name: "Piso 1",
      section_type: "floor",
      parent: @tower
    )

    assert_predicate floor, :valid?
    assert floor.save
  end

  test "child section cannot have another child section" do
    floor = @property.property_sections.create!(
      organization: @organization,
      name: "Piso 1",
      section_type: "floor",
      parent: @tower
    )

    nested = @property.property_sections.build(
      organization: @organization,
      name: "Ala B",
      section_type: "block",
      parent: floor
    )

    assert_not nested.valid?
    assert_includes nested.errors[:parent_id], I18n.t("frontend.admin.property_sections.validations.parent_must_be_root")
  end

  test "section with children cannot be assigned as child of another section" do
    @property.property_sections.create!(
      organization: @organization,
      name: "Piso 1",
      section_type: "floor",
      parent: @tower
    )

    tower_b = @property.property_sections.create!(
      organization: @organization,
      name: "Torre B",
      section_type: "tower"
    )

    @tower.parent = tower_b

    assert_not @tower.valid?
    assert_includes @tower.errors[:parent_id],
                    I18n.t("frontend.admin.property_sections.validations.cannot_nest_with_children")
  end
end
