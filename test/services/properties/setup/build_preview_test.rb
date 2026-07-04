# frozen_string_literal: true

require "test_helper"

class Properties::Setup::BuildPreviewTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Preview Property",
      property_type: PropertyTypes::BUILDING,
      status: PropertyStatuses::DRAFT,
      address_line: "Main 1",
      city: "Santiago",
      country: "Chile",
      timezone: "America/Santiago",
      metadata: {
        "setup_wizard" => {
          "structure_mode" => "manual",
          "units_mode" => "individual",
          "estimated_units" => 10
        }
      }
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "returns property counts structure tree and unit preview" do
    admin = create_user_for_organization(
      organization: @organization,
      email: "preview-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )

    section_result = PropertySections::Create.call(
      actor: admin,
      property: @property,
      parent: nil,
      attributes: { name: "Torre A", section_type: SectionTypes::TOWER }
    )
    refute section_result.invalid?, section_result.section&.errors&.full_messages&.join(", ")

    unit_result = Units::Create.call(
      actor: admin,
      property: @property,
      attributes: { identifier: "101", unit_type: UnitTypes::APARTMENT }
    )
    refute unit_result.invalid?, unit_result.unit&.errors&.full_messages&.join(", ")

    preview = Properties::Setup::BuildPreview.call(property: @property.reload, actor: admin)

    assert_equal "Preview Property", preview.dig(:property, :name)
    assert_equal 1, preview.dig(:counts, :sections)
    assert_equal 1, preview.dig(:counts, :units)
    assert_equal 1, preview.dig(:structure, :tree).size
    assert_equal "101", preview[:units].first[:identifier]
  end

  test "does not flag missing units in automatic mode before generation" do
    @property.update!(
      metadata: {
        "setup_wizard" => {
          "structure_mode" => "quick",
          "units_mode" => "automatic"
        }
      }
    )

    preview = Properties::Setup::BuildPreview.call(property: @property)

    refute_includes preview[:blocking_errors], I18n.t("frontend.admin.property_setup.step3.errors.no_units")
  end

  test "flags blocking errors when manual structure is empty" do
    preview = Properties::Setup::BuildPreview.call(property: @property)

    assert_includes preview[:blocking_errors], I18n.t("frontend.admin.property_setup.step2.errors.manual_empty")
  end

  # fix-automatic-unit-generation §8: structure counts are format-aware.
  def draft_property(property_type)
    ResidentialProperty.create!(
      organization: @organization,
      name: "Counts #{property_type} #{SecureRandom.hex(3)}",
      property_type: property_type,
      status: PropertyStatuses::DRAFT,
      country: "Chile",
      timezone: "America/Santiago"
    )
  end

  test "condominium reports non-zero level_1 (sectors) and level_2 (blocks)" do
    admin = create_user_for_organization(
      organization: @organization, email: "counts-condo@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    property = draft_property(PropertyTypes::CONDOMINIUM)
    Properties::Setup::ApplyQuickStructure.call(
      actor: admin, property: property,
      params: { level_1_count: 2, level_2_count: 3, level_1_prefix: "Sector", level_2_prefix: "Bloque" }
    )

    counts = Properties::Setup::BuildPreview.call(property: property.reload, actor: admin)[:counts]

    assert_equal 2, counts[:level_1]
    assert_equal 6, counts[:level_2]
  end

  test "single-level sector counts blocks in level_1 only, not duplicated in level_2" do
    admin = create_user_for_organization(
      organization: @organization, email: "counts-sector@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    property = draft_property(PropertyTypes::SECTOR)
    Properties::Setup::ApplyQuickStructure.call(
      actor: admin, property: property, params: { level_1_count: 4, level_1_prefix: "Bloque" }
    )

    counts = Properties::Setup::BuildPreview.call(property: property.reload, actor: admin)[:counts]

    assert_equal 4, counts[:level_1]
    assert_equal 0, counts[:level_2]
  end

  test "unit preview row shows the derived code, not the raw identifier" do
    admin = create_user_for_organization(
      organization: @organization, email: "counts-code@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    section = PropertySections::Create.call(
      actor: admin, property: @property, parent: nil,
      attributes: { name: "Torre A", section_type: SectionTypes::TOWER }
    ).section
    unit = Units::Create.call(
      actor: admin, property: @property, section_id: section.id,
      attributes: { identifier: "101", unit_type: UnitTypes::APARTMENT }
    ).unit

    row = Properties::Setup::BuildPreview.call(property: @property.reload, actor: admin)[:units].first

    assert_equal unit.code, row[:code]
    assert_not_equal unit.identifier, row[:code]
  end
end
