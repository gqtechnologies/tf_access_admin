# frozen_string_literal: true

require "test_helper"

class Admin::PropertySetup::WizardControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "wizard-ctrl-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "wizard-ctrl-client@example.test",
      role: AvailableRoles::CLIENT
    )

    @draft = ResidentialProperty.create!(
      organization: @organization,
      name: "Wizard Draft Property",
      property_type: PropertyTypes::BUILDING,
      status: PropertyStatuses::DRAFT,
      address_line: "Main 123",
      city: "Santiago",
      country: "Chile",
      timezone: "America/Santiago",
      metadata: { "setup_wizard" => { "current_step" => 2, "structure_mode" => "none" } }
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "tenant admin can open wizard" do
    sign_in_as(@tenant_admin)
    get admin_property_setup_new_wizard_path
    assert_response :success
  end

  test "unauthorized user cannot open wizard" do
    sign_in_as(@client)
    get admin_property_setup_new_wizard_path
    assert_response :redirect
  end

  test "create initializes draft property" do
    sign_in_as(@tenant_admin)

    assert_difference -> { ResidentialProperty.where(status: PropertyStatuses::DRAFT).count }, 1 do
      post admin_property_setup_create_wizard_path, params: {
        setup: {
          name: "New Wizard Property",
          property_type: PropertyTypes::BUILDING,
          address_line: "Street 1",
          city: "Santiago",
          estimated_units: 12
        }
      }
    end

    property = ResidentialProperty.order(:created_at).last
    assert_equal PropertyStatuses::DRAFT, property.status
    assert_redirected_to admin_property_setup_wizard_path(property)
  end

  test "advance moves to next step when valid" do
    sign_in_as(@tenant_admin)

    post admin_property_setup_advance_wizard_path(@draft), params: {
      setup: { structure_mode: "none", units_mode: "automatic" }
    }

    assert_redirected_to admin_property_setup_wizard_path(@draft)
    assert_equal 3, Properties::Setup::WizardState.current_step(@draft.reload)
  end

  test "confirm transitions draft to configured" do
    sign_in_as(@tenant_admin)
    Units::Create.call(
      actor: @tenant_admin,
      property: @draft,
      attributes: { identifier: "101", unit_type: UnitTypes::APARTMENT }
    )
    Properties::Setup::WizardState.merge!(@draft, current_step: 5)
    @draft.save!

    post admin_property_setup_confirm_wizard_path(@draft)

    assert_equal PropertyStatuses::CONFIGURED, @draft.reload.status
    assert_redirected_to admin_property_setup_wizard_path(@draft, completed: true)
  end

  test "cancel with delete removes draft property" do
    sign_in_as(@tenant_admin)

    post admin_property_setup_cancel_wizard_path(@draft), params: { delete_draft: true }

    assert @draft.reload.deleted_at.present?
    assert_redirected_to admin_residential_properties_path
  end

  test "create section adds section to draft property" do
    sign_in_as(@tenant_admin)

    assert_difference -> { @draft.property_sections.count }, 1 do
      post admin_property_setup_create_section_wizard_path(@draft), params: {
        property_section: { name: "Torre A", section_type: SectionTypes::TOWER }
      }
    end

    assert_redirected_to admin_property_setup_wizard_path(@draft)
  end

  test "back moves to previous step" do
    sign_in_as(@tenant_admin)
    Properties::Setup::WizardState.merge!(@draft, current_step: 3)
    @draft.save!

    post admin_property_setup_back_wizard_path(@draft)

    assert_redirected_to admin_property_setup_wizard_path(@draft)
    assert_equal 2, Properties::Setup::WizardState.current_step(@draft.reload)
  end

  test "tenant admin cannot access draft from another organization" do
    other_draft = ActsAsTenant.with_tenant(organizations(:two)) do
      ResidentialProperty.create!(
        organization: organizations(:two),
        name: "Other Org Draft",
        property_type: PropertyTypes::BUILDING,
        status: PropertyStatuses::DRAFT,
        country: "Chile",
        timezone: "America/Santiago"
      )
    end

    sign_in_as(@tenant_admin)
    get admin_property_setup_wizard_path(other_draft)

    assert_redirected_to admin_residential_properties_path
  end

  test "create unit adds unit to draft property" do
    sign_in_as(@tenant_admin)

    assert_difference -> { @draft.units.count }, 1 do
      post admin_property_setup_create_unit_wizard_path(@draft), params: {
        unit: { identifier: "A-101", unit_type: UnitTypes::APARTMENT }
      }
    end

    assert_redirected_to admin_property_setup_wizard_path(@draft)
  end

  test "cancel without delete keeps configured property" do
    configured = ResidentialProperty.create!(
      organization: @organization,
      name: "Configured Property",
      property_type: PropertyTypes::BUILDING,
      status: PropertyStatuses::CONFIGURED,
      country: "Chile",
      timezone: "America/Santiago"
    )

    sign_in_as(@tenant_admin)
    post admin_property_setup_cancel_wizard_path(configured), params: { delete_draft: false }

    assert configured.reload.persisted?
    assert_redirected_to admin_residential_properties_path
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
