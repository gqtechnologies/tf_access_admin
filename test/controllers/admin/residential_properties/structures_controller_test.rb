# frozen_string_literal: true

require "test_helper"

# Access control for the residential structure screen/DTO
# (improve-property-sections §6). The tree and its units must only reach actors
# with +manage_sections+ on the concrete property; generic property access is not
# enough.
class Admin::ResidentialProperties::StructuresControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization

    @property = create_property(@organization, "Structure Auth Property")
    @other_property = create_property(@organization, "Structure Auth Property Two")
    @tower = @property.property_sections.create!(
      organization: @organization,
      name: "Torre A",
      section_type: SectionTypes::TOWER
    )
    @unit = create_unit(@property, "STR-101")
    @unit.update!(property_section: @tower)

    @structure_path = admin_residential_property_structure_path(@property)

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "structure-tenant-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "tenant admin of the organization can access the structure" do
    sign_in_as(@tenant_admin)
    inertia_get @structure_path

    assert_response :success
    assert_equal 1, inertia_props["section_tree"].size
    assert_equal "Torre A", inertia_props["section_tree"].first["name"]
  end

  test "property admin with active assignment can access the structure" do
    admin = create_staff_user(
      organization: @organization,
      email: "structure-property-admin@example.test",
      staff_type: StaffTypes::MANAGER,
      property: @property
    )

    sign_in_as(admin)
    inertia_get @structure_path

    assert_response :success
    assert_equal "Torre A", inertia_props["section_tree"].first["name"]
  end

  test "user without manage_sections receives no sections or units" do
    concierge = create_staff_user(
      organization: @organization,
      email: "structure-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE,
      property: @property
    )

    sign_in_as(concierge)
    inertia_get @structure_path

    assert_response :redirect
    assert_nil inertia_props_or_nil&.dig("section_tree")
  end

  test "resident of a unit cannot access the structure" do
    resident = create_resident_user(
      organization: @organization,
      email: "structure-resident@example.test",
      unit: @unit
    )

    sign_in_as(resident)
    inertia_get @structure_path

    assert_response :redirect
  end

  test "inactive assignment grants no access" do
    admin = assigned_property_admin("structure-inactive@example.test")
    StaffAssignment.find_by(residential_property: @property).update!(status: "inactive")

    sign_in_as(admin)
    inertia_get @structure_path

    assert_response :redirect
  end

  test "future-dated assignment grants no access" do
    admin = assigned_property_admin("structure-future@example.test")
    StaffAssignment.find_by(residential_property: @property)
      .update!(starts_at: Date.current + 5.days)

    sign_in_as(admin)
    inertia_get @structure_path

    assert_response :redirect
  end

  test "expired assignment grants no access" do
    admin = assigned_property_admin("structure-expired@example.test")
    StaffAssignment.find_by(residential_property: @property)
      .update!(starts_at: Date.current - 10.days, ends_at: Date.current - 1.day)

    sign_in_as(admin)
    inertia_get @structure_path

    assert_response :redirect
  end

  test "actor assigned to another property cannot access this property" do
    admin = create_staff_user(
      organization: @organization,
      email: "structure-other-property@example.test",
      staff_type: StaffTypes::MANAGER,
      property: @other_property
    )

    sign_in_as(admin)
    inertia_get @structure_path

    assert_response :redirect
  end

  test "user from another organization cannot access the structure" do
    sign_in_as(@tenant_admin)

    foreign_property = ActsAsTenant.with_tenant(@other_organization) do
      create_property(@other_organization, "Foreign Structure Property")
    end

    inertia_get admin_residential_property_structure_path(foreign_property)

    assert_response :redirect
  end

  private

  def assigned_property_admin(email)
    create_staff_user(
      organization: @organization,
      email: email,
      staff_type: StaffTypes::MANAGER,
      property: @property
    )
  end

  def inertia_props_or_nil
    JSON.parse(response.body)["props"]
  rescue JSON::ParserError
    nil
  end

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
