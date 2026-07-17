# frozen_string_literal: true

require "test_helper"

class Admin::People::BulkImportsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include UserTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "people-bulk-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "people-bulk-client@example.test",
      role: AvailableRoles::CLIENT
    )

    @bulk_import = BulkImport.create!(
      organization: @organization,
      created_by: @tenant_admin,
      import_type: BulkImport::IMPORT_TYPES[:users],
      status: "validated"
    )

    @other_bulk_import = ActsAsTenant.with_tenant(@other_organization) do
      other_admin = create_user_for_organization(
        organization: @other_organization,
        email: "other-org-bulk-admin@example.test",
        role: AvailableRoles::TENANT_ADMIN
      )
      BulkImport.create!(
        organization: @other_organization,
        created_by: other_admin,
        import_type: BulkImport::IMPORT_TYPES[:users],
        status: "validated"
      )
    end
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "authorized admin can fetch status of a people bulk import" do
    sign_in_as(@tenant_admin)

    get status_admin_people_bulk_import_path(@bulk_import)

    assert_response :success
  end

  test "user without manage_people cannot access a people bulk import" do
    sign_in_as(@client)

    get status_admin_people_bulk_import_path(@bulk_import)

    assert_response :not_found
  end

  test "bulk import belonging to another organization is not found" do
    sign_in_as(@tenant_admin)

    get status_admin_people_bulk_import_path(@other_bulk_import)

    assert_response :not_found
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
