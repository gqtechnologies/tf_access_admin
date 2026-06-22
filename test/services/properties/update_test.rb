# frozen_string_literal: true

require "test_helper"

# Properties::Update domain service (improve-property-foundation §7).
class Properties::UpdateTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "prop-update-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @property = create_property(@organization, "Update Target")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # 7.6 -----------------------------------------------------------------------
  test "7.6 applies descriptive changes and an active/inactive transition" do
    result = Properties::Update.call(
      actor: @tenant_admin,
      property: @property,
      attributes: { city: "Santiago", status: PropertyStatuses::INACTIVE }
    )

    assert result.success?
    assert_equal "Santiago", @property.reload.city
    assert_equal PropertyStatuses::INACTIVE, @property.status
  end

  # §3.6 ----------------------------------------------------------------------
  test "rejects archiving through an ordinary update" do
    result = Properties::Update.call(
      actor: @tenant_admin,
      property: @property,
      attributes: { status: PropertyStatuses::ARCHIVED }
    )

    assert result.invalid?
    assert result.errors.key?(:status)
    assert_equal PropertyStatuses::ACTIVE, @property.reload.status
  end

  # 7.4 -----------------------------------------------------------------------
  test "7.4 rejects a duplicate normalized name on update" do
    create_property(@organization, "Existing Name")

    result = Properties::Update.call(
      actor: @tenant_admin,
      property: @property,
      attributes: { name: "existing name" }
    )

    assert result.invalid?
    assert result.errors.key?(:name)
  end
end
