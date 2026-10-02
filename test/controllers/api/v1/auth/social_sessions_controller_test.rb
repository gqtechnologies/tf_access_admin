# frozen_string_literal: true

require "test_helper"

# POST /api/v1/auth/social — OpenSpec 2026-10-02-mobile-social-sign-in.
class Api::V1::Auth::SocialSessionsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include SocialTokenTestHelper

  setup do
    @organization = organizations(:one)
    @other_org = organizations(:two)
    host! "#{@organization.subdomain}.example.com"
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── sign up ─────────────────────────────────────────────────────────────────

  test "unknown email asks for the profile before creating anything" do
    assert_no_difference "User.count" do
      sign_in_with("google", email: "new-visitor@example.com", name: "Nueva Visita")
    end

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal "profile_required", body["code"]
    assert_equal [ "dni" ], body["missing"]
    assert_equal "Nueva Visita", body["suggested_name"]
  end

  test "Apple without a name asks for name and document" do
    sign_in_with("apple", email: "apple-new@example.com")

    assert_equal %w[name dni], response.parsed_body["missing"]
  end

  test "creates a confirmed visitor account and returns a session" do
    assert_difference "User.count", 1 do
      sign_in_with("apple", { email: "apple-visitor@example.com" }, name: "Ana Apple", dni: "11.111.111-1")
    end

    assert_response :ok
    data = response.parsed_body["data"]
    assert data["token"].present?
    assert_equal data["token"], response.headers["Authorization"].delete_prefix("Bearer ")
    assert_equal true, data["created"]
    assert_equal "visitor", data.dig("user", "role")
    assert_equal "Ana Apple", data.dig("user", "name")

    user = User.find_by!(email: "apple-visitor@example.com")
    assert user.confirmed?
    assert_equal "11.111.111-1", user.dni
    assert user.member_of_tenant?(@organization)
  end

  test "the new session works on the private API" do
    sign_in_with("google", { email: "session-check@example.com", name: "Sesión Ok" }, dni: "22.222.222-2")
    token = response.parsed_body.dig("data", "token")

    get api_v1_private_invitations_path, headers: { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }

    assert_response :ok
  end

  test "a person already invited by email is linked instead of duplicated" do
    person = ActsAsTenant.with_tenant(@organization) do
      Person.create!(
        organization: @organization, display_name: "Invitada Previa", contact_email: "invited-before@example.com",
        person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
      )
    end

    assert_no_difference "Person.count" do
      sign_in_with("google", { email: "invited-before@example.com", name: "Invitada Previa" }, dni: "33.333.333-3")
    end

    assert_response :ok
    assert_equal User.find_by!(email: "invited-before@example.com").id, person.reload.user_id
    assert_equal "visitor", response.parsed_body.dig("data", "user", "role")
  end

  # ─── sign in ─────────────────────────────────────────────────────────────────

  test "existing member signs in to their own account with their role" do
    resident = existing_user(@organization, "resident-social@example.com", AvailableRoles::TENANT_ADMIN)

    assert_no_difference "User.count" do
      sign_in_with("google", email: resident.email)
    end

    assert_response :ok
    data = response.parsed_body["data"]
    assert_equal resident.id, data.dig("user", "id")
    assert_equal "tenant_admin", data.dig("user", "role")
    assert_equal false, data["created"]
  end

  test "account from another organization joins this one as a visitor" do
    outsider = existing_user(@other_org, "outsider-social@example.com", AvailableRoles::CLIENT)

    assert_no_difference "User.count" do
      sign_in_with("apple", email: outsider.email)
    end

    assert_response :ok
    assert_equal "visitor", response.parsed_body.dig("data", "user", "role")
    assert outsider.reload.member_of_tenant?(@organization)
  end

  test "deactivated account is rejected" do
    user = existing_user(@organization, "deactivated-social@example.com", AvailableRoles::CLIENT)
    user.update!(deactivated_at: Time.current)

    sign_in_with("google", email: user.email)

    assert_response :unauthorized
    assert_equal I18n.t("api.errors.account_deactivated"), response.parsed_body["error"]
  end

  # ─── rejections ──────────────────────────────────────────────────────────────

  test "unverified email is rejected" do
    assert_no_difference "User.count" do
      sign_in_with("google", { email: "unverified@example.com", email_verified: false }, name: "X", dni: "1")
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("api.social.email_required"), response.parsed_body["error"]
  end

  test "a token for another app is rejected" do
    existing_user(@organization, "victim@example.com", AvailableRoles::TENANT_ADMIN)

    sign_in_with("apple", email: "victim@example.com", aud: "com.someone.else")

    assert_response :unauthorized
    assert_nil response.headers["Authorization"]
  end

  test "Google answers 503 until it is configured" do
    with_social_providers do
      ENV["GOOGLE_SIGN_IN_CLIENT_IDS"] = ""
      post api_v1_auth_social_path, params: { provider: "google", id_token: social_token("google", email: "a@example.com") }
    end

    assert_response :service_unavailable
  end

  test "unknown organization is a 401" do
    host! "no-such-org.example.com"
    sign_in_with("apple", email: "a@example.com")

    assert_response :unauthorized
  end

  private

  def sign_in_with(provider, claims, extra = {})
    with_social_providers do
      post api_v1_auth_social_path, params: { provider: provider, id_token: social_token(provider, **claims) }.merge(extra)
    end
  end

  def existing_user(organization, email, role)
    user = create_user_for_organization(organization: organization, email: email, role: role)
    ActsAsTenant.current_tenant = nil
    user
  end
end
