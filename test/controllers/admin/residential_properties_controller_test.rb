# frozen_string_literal: true

require "test_helper"

class Admin::ResidentialPropertiesControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Controller Property P")
    @other_property = create_property(@organization, "Controller Property Q")

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "rp-ctrl-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @property_admin = create_staff_user(
      organization: @organization,
      email: "rp-ctrl-admin-prop@example.test",
      staff_type: StaffTypes::MANAGER,
      property: @property
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "rp-ctrl-client@example.test",
      role: AvailableRoles::CLIENT
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "tenant_admin create delegates to Properties::Create" do
    sign_in_as @tenant_admin

    assert_difference -> { ResidentialProperty.count }, 1 do
      post admin_residential_properties_path, params: {
        residential_property: valid_property_params(name: "Controller Created Property")
      }
    end

    assert_redirected_to admin_residential_properties_path
    created = ResidentialProperty.order(:created_at).last
    assert_equal PropertyStatuses::ACTIVE, created.status
    assert_equal @organization.id, created.organization_id
  end

  test "create rejects duplicate normalized name with field errors" do
    sign_in_as @tenant_admin

    post admin_residential_properties_path, params: {
      residential_property: valid_property_params(name: @property.name)
    }

    assert_redirected_to new_admin_residential_property_path
    follow_redirect!
    assert_includes response.body, "errors"
  end

  test "property_admin cannot create properties" do
    sign_in_as @property_admin

    assert_no_difference -> { ResidentialProperty.count } do
      post admin_residential_properties_path, params: {
        residential_property: valid_property_params(name: "Denied Create Property")
      }
    end

    assert_response :redirect
  end

  test "tenant_admin update delegates to Properties::Update" do
    sign_in_as @tenant_admin

    patch admin_residential_property_path(@property), params: {
      residential_property: { name: "Controller Updated Property", status: PropertyStatuses::INACTIVE }
    }

    assert_redirected_to edit_admin_residential_property_path(@property)
    assert_equal "Controller Updated Property", @property.reload.name
    assert_equal PropertyStatuses::INACTIVE, @property.status
  end

  test "update rejects archive status through ordinary update" do
    sign_in_as @tenant_admin

    patch admin_residential_property_path(@property), params: {
      residential_property: { status: PropertyStatuses::ARCHIVED }
    }

    assert_redirected_to edit_admin_residential_property_path(@property)
    assert_equal PropertyStatuses::ACTIVE, @property.reload.status
  end

  test "tenant_admin archive delegates to Properties::Archive" do
    sign_in_as @tenant_admin

    post archive_admin_residential_property_path(@property)

    assert_redirected_to admin_residential_properties_path
    assert_equal PropertyStatuses::ARCHIVED, @property.reload.status
    assert ResidentialProperty.exists?(@property.id)
  end

  test "property_admin cannot archive properties" do
    sign_in_as @property_admin

    post archive_admin_residential_property_path(@property)

    assert_response :redirect
    assert_equal PropertyStatuses::ACTIVE, @property.reload.status
  end

  test "index exposes backend-driven permissions in serializer props" do
    sign_in_as @tenant_admin
    inertia_get admin_residential_properties_path

    assert_response :success
    row = inertia_props["residential_properties"].find { |property| property["id"] == @property.id }
    assert row["permissions"]["archive"]
    assert_includes row["actions"], "archive"
  end

  test "record loading uses policy scope" do
    sign_in_as @tenant_admin
    other_org_property = ActsAsTenant.with_tenant(@other_organization) do
      create_property(@other_organization, "Other Org Controller Property")
    end

    patch admin_residential_property_path(other_org_property), params: {
      residential_property: { name: "Cross Org Attempt" }
    }

    assert_redirected_to admin_residential_properties_path
    assert_not_equal "Cross Org Attempt", other_org_property.reload.name
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end

  def valid_property_params(name:)
    {
      name: name,
      property_type: PropertyTypes::BUILDING,
      country: "Chile",
      timezone: "America/Santiago",
      status: PropertyStatuses::INACTIVE
    }
  end
end
