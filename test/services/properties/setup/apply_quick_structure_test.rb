# frozen_string_literal: true

require "test_helper"

class Properties::Setup::ApplyQuickStructureTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "apply-quick@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  def draft_property(property_type)
    ResidentialProperty.create!(
      organization: @organization,
      name: "Quick #{property_type}",
      property_type: property_type,
      status: PropertyStatuses::DRAFT,
      country: "Chile",
      timezone: "America/Santiago"
    )
  end

  test "building persists tower and floor sections from the format" do
    property = draft_property(PropertyTypes::BUILDING)

    result = Properties::Setup::ApplyQuickStructure.call(
      actor: @tenant_admin,
      property: property,
      params: { level_1_count: 2, level_2_count: 3, level_1_prefix: "Torre", level_2_prefix: "Piso" }
    )

    assert result.success?
    towers = property.property_sections.where(section_type: SectionTypes::TOWER)
    floors = property.property_sections.where(section_type: SectionTypes::FLOOR)
    assert_equal 2, towers.count
    assert_equal 6, floors.count
    assert(floors.all? { |f| towers.pluck(:id).include?(f.parent_id) })
  end

  test "sector persists a single level of block sections" do
    property = draft_property(PropertyTypes::SECTOR)

    result = Properties::Setup::ApplyQuickStructure.call(
      actor: @tenant_admin,
      property: property,
      params: { level_1_count: 4, level_1_prefix: "Bloque" }
    )

    assert result.success?
    blocks = property.property_sections.where(section_type: SectionTypes::BLOCK)
    assert_equal 4, blocks.count
    assert(blocks.all? { |b| b.parent_id.nil? })
  end

  test "re-applying replaces previously generated sections" do
    property = draft_property(PropertyTypes::SECTOR)

    Properties::Setup::ApplyQuickStructure.call(
      actor: @tenant_admin,
      property: property,
      params: { level_1_count: 4, level_1_prefix: "Bloque" }
    )
    Properties::Setup::ApplyQuickStructure.call(
      actor: @tenant_admin,
      property: property,
      params: { level_1_count: 2, level_1_prefix: "Bloque" }
    )

    assert_equal 2, property.property_sections.count
  end
end
