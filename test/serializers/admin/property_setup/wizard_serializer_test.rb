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
end
