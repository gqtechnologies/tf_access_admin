# frozen_string_literal: true

require "test_helper"

class OnboardingAcceptancesControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper

  setup do
    @organization = organizations(:one)
    host! "#{@organization.subdomain}.example.com"
    @result = ActsAsTenant.with_tenant(@organization) do
      Accounts::InvitePerson.call(
        organization: @organization,
        email: "accept-me@example.test",
        first_name: "Accept",
        last_name: "Me",
        document_number: "61.616.161-6"
      )
    end
  end

  teardown { ActsAsTenant.current_tenant = nil }

  test "show renders the neutral acceptance page" do
    inertia_get onboarding_acceptance_path(@result.token)

    assert_response :success
    assert_equal "onboarding/accept", inertia_component
    assert_equal @organization.name, inertia_props["organization_name"]
    assert inertia_props["needs_account"]
  end

  test "show with an invalid token renders invalid" do
    inertia_get onboarding_acceptance_path("bogus-token")
    assert_response :unprocessable_entity
    assert_equal "onboarding/invalid", inertia_component
  end

  test "create accepts the invitation and creates a confirmed account" do
    post onboarding_acceptance_path(@result.token), params: { password: "Password1@" }

    assert_redirected_to new_user_session_path
    person = @result.person.reload
    assert person.user_id.present?
    assert person.user.confirmed?
    assert_equal OrganizationMembership::STATUS_ACTIVE, person.organization_membership.status
  end
end
