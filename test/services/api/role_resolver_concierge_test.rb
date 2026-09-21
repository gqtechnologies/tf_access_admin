# frozen_string_literal: true

require "test_helper"

# operational-roles-and-permissions "API role for concierge staff".
class Api::RoleResolverConciergeTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset
    @property = create_property(@organization, "Role Resolver Property")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "active concierge assignment resolves to concierge" do
    user = concierge("rr-concierge@example.test")

    assert_equal "concierge", Api::RoleResolver.call(user, @organization)
  end

  test "administrative role wins over the concierge assignment" do
    user = concierge("rr-admin@example.test", role: AvailableRoles::TENANT_ADMIN)

    assert_equal AvailableRoles::TENANT_ADMIN, Api::RoleResolver.call(user, @organization)
  end

  test "visitor role does not outrank the concierge assignment" do
    user = concierge("rr-visitor-concierge@example.test", role: AvailableRoles::VISITOR)

    assert_equal "concierge", Api::RoleResolver.call(user, @organization)
  end

  test "visitor without assignment stays visitor" do
    user = create_user_for_organization(
      organization: @organization, email: "rr-visitor@example.test", role: AvailableRoles::VISITOR
    )

    assert_equal AvailableRoles::VISITOR, Api::RoleResolver.call(user, @organization)
  end

  test "inactive or ended assignment resolves to resident" do
    inactive = concierge("rr-inactive@example.test")
    StaffAssignment.where(person: inactive.person_for(@organization)).update_all(status: "inactive")

    ended = concierge("rr-ended@example.test")
    StaffAssignment.where(person: ended.person_for(@organization))
                   .update_all(starts_at: 30.days.ago.to_date, ends_at: 2.days.ago.to_date)

    assert_equal "resident", Api::RoleResolver.call(inactive, @organization)
    assert_equal "resident", Api::RoleResolver.call(ended, @organization)
  end

  test "non-concierge staff resolves to resident" do
    user = create_staff_user(
      organization: @organization, email: "rr-cleaning@example.test",
      staff_type: StaffTypes::CLEANING, property: @property
    )

    assert_equal "resident", Api::RoleResolver.call(user, @organization)
  end

  private

  def concierge(email, role: AvailableRoles::CLIENT)
    create_staff_user(
      organization: @organization, email: email,
      staff_type: StaffTypes::CONCIERGE, property: @property, role: role
    )
  end
end
