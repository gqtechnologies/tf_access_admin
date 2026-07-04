# frozen_string_literal: true

require "test_helper"

class Admin::PropertySetup::WizardSerializerTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "wizard-serializer@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  def draft_property(property_type)
    ResidentialProperty.create!(
      organization: @organization,
      name: "Serializer #{property_type}",
      property_type: property_type,
      status: PropertyStatuses::DRAFT,
      country: "Chile",
      timezone: "America/Santiago"
    )
  end

  def serialize(property)
    Admin::PropertySetup::WizardSerializer.new(
      property: property,
      current_user: @tenant_admin,
      step: 2
    ).as_json
  end

  test "includes structure_format and units_in for a mapped property type" do
    json = serialize(draft_property(PropertyTypes::BUILDING))

    assert_equal SectionTypes::FLOOR, json[:units_in]
    levels = json[:structure_format]["levels"]
    assert_equal [ SectionTypes::TOWER, SectionTypes::FLOOR ], levels.map { |l| l["section_type"] }
  end

  test "structure_format and units_in are nil for an unmapped property type" do
    json = serialize(draft_property(PropertyTypes::OTHER))

    assert_nil json[:structure_format]
    assert_nil json[:units_in]
  end

  test "preview counts.units are identical across step 4, step 5, and the completed view" do
    property = draft_property(PropertyTypes::BUILDING)
    section = PropertySections::Create.call(
      actor: @tenant_admin, property: property, parent: nil,
      attributes: { name: "Torre A", section_type: SectionTypes::TOWER }
    ).section
    Units::Create.call(
      actor: @tenant_admin, property: property, section_id: section.id,
      attributes: { identifier: "101", unit_type: UnitTypes::APARTMENT }
    )
    property.reload

    step4_units = Admin::PropertySetup::WizardSerializer.new(
      property: property, current_user: @tenant_admin, step: 4
    ).as_json.dig(:preview, :counts, :units)
    step5_units = Admin::PropertySetup::WizardSerializer.new(
      property: property, current_user: @tenant_admin, step: 5
    ).as_json.dig(:preview, :counts, :units)

    assert_equal 1, step4_units
    assert_equal step4_units, step5_units
  end

  test "preview property contract does not expose an estimated_units field" do
    json = serialize(draft_property(PropertyTypes::BUILDING))

    refute json.dig(:preview, :property).key?(:estimated_units)
  end
end
