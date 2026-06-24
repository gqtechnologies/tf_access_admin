# frozen_string_literal: true

require "test_helper"

class Admin::ResidentialProperties::UnitsMutationsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @property = create_property(@organization, "Units Mutation Property")
    @other_property = create_property(@organization, "Units Mutation Property Two")
    @floor = @property.property_sections.create!(
      organization: @organization,
      name: "Piso 1",
      section_type: SectionTypes::FLOOR
    )
    @unit = create_unit(@property, "MUT-101")
    @unit.update!(property_section: @floor)

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "units-mut-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "units-mut-client@example.test",
      role: AvailableRoles::CLIENT
    )

    @structure_path = admin_residential_property_structure_path(@property)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "create delegates to the service and derives organization from the property" do
    sign_in_as(@tenant_admin)

    assert_difference -> { @property.units.count }, 1 do
      post admin_residential_property_units_path(@property), params: {
        unit: {
          identifier: "MUT-202",
          unit_type: UnitTypes::APARTMENT,
          property_section_id: @floor.id
        }
      }
    end

    unit = @property.units.find_by(identifier: "MUT-202")
    assert_equal @organization.id, unit.organization_id
    assert_equal UnitStatuses::AVAILABLE, unit.status
    assert_redirected_to @structure_path
  end

  test "create ignores client-supplied organization and property ids" do
    sign_in_as(@tenant_admin)

    post admin_residential_property_units_path(@property), params: {
      unit: {
        identifier: "MUT-303",
        unit_type: UnitTypes::APARTMENT,
        organization_id: organizations(:two).id,
        residential_property_id: @other_property.id,
        normalized_identifier: "forged"
      }
    }

    unit = @property.units.find_by(identifier: "MUT-303")
    assert_equal @organization.id, unit.organization_id
    assert_equal @property.id, unit.residential_property_id
    assert_equal "mut-303", unit.normalized_identifier
  end

  test "update delegates descriptive changes to the service" do
    sign_in_as(@tenant_admin)

    patch admin_residential_property_unit_path(@property, @unit), params: {
      unit: { display_name: "Renamed Unit", status: UnitStatuses::MAINTENANCE }
    }

    @unit.reload
    assert_equal "Renamed Unit", @unit.display_name
    assert_equal UnitStatuses::MAINTENANCE, @unit.status
    assert_equal @floor.id, @unit.property_section_id
  end

  test "move delegates section changes to the service" do
    sign_in_as(@tenant_admin)

    post move_admin_residential_property_unit_path(@property, @unit), params: {
      unit: { property_section_id: nil }
    }

    assert_nil @unit.reload.property_section_id
    assert_redirected_to @structure_path
  end

  test "archive delegates to the service without soft delete" do
    sign_in_as(@tenant_admin)

    post archive_admin_residential_property_unit_path(@property, @unit)

    assert_equal UnitStatuses::ARCHIVED, @unit.reload.status
    assert_nil @unit.deleted_at
    assert_redirected_to @structure_path
  end

  test "restore delegates to the service for soft-deleted units" do
    sign_in_as(@tenant_admin)
    Units::SoftDelete.call(actor: @tenant_admin, unit: @unit)

    post restore_admin_residential_property_unit_path(@property, @unit)

    assert_nil @unit.reload.deleted_at
    assert_redirected_to @structure_path
  end

  test "index search returns only units from the authorized property scope" do
    sign_in_as(@tenant_admin)
    create_unit(@other_property, "MUT-101")

    get admin_residential_property_units_path(@property), params: { search: "mut-101" }

    assert_response :success
    ids = response.parsed_body.fetch("units").map { |row| row["id"] }
    assert_includes ids, @unit.id
    assert_equal 1, ids.size
  end

  test "mutations are forbidden for users without manage_units" do
    sign_in_as(@client)

    assert_no_difference -> { @property.units.count } do
      post admin_residential_property_units_path(@property), params: {
        unit: { identifier: "FORBIDDEN", unit_type: UnitTypes::APARTMENT }
      }
    end

    patch admin_residential_property_unit_path(@property, @unit), params: {
      unit: { display_name: "Blocked" }
    }
    assert_nil @unit.reload.display_name
    assert_equal "MUT-101", @unit.identifier
  end

  test "invalid create redirects with inertia field errors" do
    sign_in_as(@tenant_admin)
    create_unit(@property, "DUP-MUT")

    assert_no_difference -> { @property.units.count } do
      post admin_residential_property_units_path(@property), params: {
        unit: { identifier: "dup-mut", unit_type: UnitTypes::APARTMENT }
      }
    end

    assert_redirected_to @structure_path
    assert session[:inertia_errors].key?(:identifier)
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: {
      user: { email: user.email, password: "password1" }
    }
  end
end
