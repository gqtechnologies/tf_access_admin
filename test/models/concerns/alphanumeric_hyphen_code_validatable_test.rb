# frozen_string_literal: true

require "test_helper"

class AlphanumericHyphenCodeValidatableTest < ActiveSupport::TestCase
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

    @section = @property.property_sections.create!(
      organization: @organization,
      name: "Torre A",
      section_type: "tower"
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "normalize_identifier converts spaces to hyphens and downcases" do
    assert_equal "depto-101", AlphanumericHyphenCodeValidatable.normalize_identifier("DEPTO 101")
  end

  test "property section accepts valid code" do
    @section.code = "TORRE-A-01"

    assert_predicate @section, :valid?
  end

  test "property section rejects invalid code" do
    @section.code = "TORRE_A"

    assert_not @section.valid?
    assert_includes @section.errors[:code], I18n.t("frontend.admin.validations.alphanumeric_hyphen_code_invalid")
  end

  test "property section allows blank code" do
    @section.code = nil

    assert_predicate @section, :valid?
  end

  test "unit rejects invalid identifier" do
    unit = build_unit(identifier: "Depto_101")

    assert_not unit.valid?
    assert_includes unit.errors[:identifier], I18n.t("frontend.admin.validations.identifier_format_invalid")
  end

  test "unit accepts identifier with spaces and assigns normalized_identifier" do
    unit = build_unit(identifier: "DEPTO 101")

    assert_predicate unit, :valid?
    assert_equal "depto-101", unit.normalized_identifier
  end

  test "unit accepts hyphenated identifier" do
    unit = build_unit(identifier: "101-A")

    assert_predicate unit, :valid?
    assert_equal "101-a", unit.normalized_identifier
  end

  private

  def build_unit(identifier:)
    Unit.new(
      organization: @organization,
      residential_property: @property,
      property_section: @section,
      unit_type: "apartment",
      identifier: identifier,
      status: "available"
    )
  end
end
