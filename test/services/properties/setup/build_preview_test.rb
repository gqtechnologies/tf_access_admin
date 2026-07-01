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
end
