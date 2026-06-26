# frozen_string_literal: true

require "test_helper"

class Properties::Setup::ValidateStepTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @property = ResidentialProperty.create!(
      organization: @organization,
      name: "Validate Step Property",
      property_type: PropertyTypes::BUILDING,
      status: PropertyStatuses::DRAFT,
      address_line: "Addr 1",
      city: "Santiago",
      country: "Chile",
      timezone: "America/Santiago",
      metadata: { "setup_wizard" => { "structure_mode" => "none", "units_mode" => "automatic" } }
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "step 2 passes for none structure mode" do
    result = Properties::Setup::ValidateStep.new(
      property: @property,
      step: 2,
      attributes: { structure_mode: "none" }
    ).call

    assert result[:valid]
  end

  test "step 3 requires units for individual mode" do
    result = Properties::Setup::ValidateStep.new(
      property: @property,
      step: 3,
      attributes: { units_mode: "individual" }
    ).call

    refute result[:valid]
  end

  test "generate structure preview paginates nodes" do
    preview = Properties::Setup::GenerateStructurePreview.call(
      params: { towers: 2, floors_per_tower: 3, units_per_floor: 4 },
      page: 1,
      per_page: 5
    )

    assert_equal 5, preview[:nodes].size
    assert_equal 8, preview[:pagination][:total]
    assert_equal 2, preview[:counts][:towers]
  end

  test "generate units preview paginates rows" do
    Properties::Setup::WizardState.merge!(@property, estimated_units: 12)
    @property.save!

    preview = Properties::Setup::GenerateUnitsPreview.call(
      property: @property,
      params: { quantity_per_floor: 4 },
      page: 1,
      per_page: 5
    )

    assert_equal 5, preview[:rows].size
    assert_equal 12, preview[:total_units]
    assert_equal 3, preview[:pagination][:total_pages]
  end
end
