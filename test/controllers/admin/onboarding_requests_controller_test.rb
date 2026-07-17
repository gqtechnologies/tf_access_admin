# frozen_string_literal: true

require "test_helper"

class Admin::OnboardingRequestsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include ActionMailer::TestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @admin = create_user_for_organization(
      organization: @organization, email: "onb-admin@example.test", role: AvailableRoles::TENANT_ADMIN
    )
    @client = create_user_for_organization(
      organization: @organization, email: "onb-client@example.test", role: AvailableRoles::CLIENT
    )
  end

  teardown { ActsAsTenant.current_tenant = nil }

  test "index renders for a manager" do
    sign_in_as(@admin)
    inertia_get admin_onboarding_requests_path

    assert_response :success
    assert_equal "admin/onboarding_requests/index", inertia_component
  end

  test "create invites a person and enqueues the invitation email" do
    sign_in_as(@admin)

    assert_difference -> { OnboardingRequest.count }, 1 do
      assert_enqueued_emails 1 do
        post admin_onboarding_requests_path, params: {
          onboarding_request: { email: "invitee@example.test", first_name: "Inv", last_name: "Itee" }
        }
      end
    end

    assert_redirected_to admin_onboarding_requests_path
  end

  test "a non-manager cannot create an invitation" do
    sign_in_as(@client)

    assert_no_difference -> { OnboardingRequest.count } do
      post admin_onboarding_requests_path, params: {
        onboarding_request: { email: "blocked@example.test" }
      }
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
