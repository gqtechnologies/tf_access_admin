# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization

    @user = create_user_for_organization(
      organization: @organization,
      email: "api-reset@example.com",
      role: AvailableRoles::CLIENT
    )

    ActsAsTenant.current_tenant = nil
    host! "#{@organization.subdomain}.example.com"
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "member gets the reset email and a 202" do
    assert_emails 1 do
      post api_v1_auth_password_path, params: { email: @user.email }
    end

    assert_response :accepted
    assert_equal "requested", response.parsed_body.dig("data", "status")
    assert @user.reload.reset_password_token.present?
  end

  test "email lookup ignores case and surrounding spaces" do
    assert_emails 1 do
      post api_v1_auth_password_path, params: { email: "  API-Reset@Example.com " }
    end

    assert_response :accepted
  end

  test "reset link points at the organization subdomain" do
    post api_v1_auth_password_path, params: { email: @user.email }

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email ], mail.to
    assert_match %r{https?://#{Regexp.escape(@organization.subdomain)}\.[^/"]+/users/password/edit\?reset_password_token=},
      mail.html_part&.body&.to_s || mail.body.to_s
  end

  test "unknown email answers the same 202 without sending" do
    assert_no_emails do
      post api_v1_auth_password_path, params: { email: "nobody@example.com" }
    end

    assert_response :accepted
    assert_equal "requested", response.parsed_body.dig("data", "status")
  end

  test "user of another organization gets no email" do
    other = create_user_for_organization(
      organization: organizations(:two),
      email: "api-reset-other@example.com",
      role: AvailableRoles::CLIENT
    )
    ActsAsTenant.current_tenant = nil

    assert_no_emails do
      post api_v1_auth_password_path, params: { email: other.email }
    end

    assert_response :accepted
  end

  test "deactivated member gets no email" do
    @user.update!(deactivated_at: Time.current)

    assert_no_emails do
      post api_v1_auth_password_path, params: { email: @user.email }
    end

    assert_response :accepted
  end

  test "unconfirmed member gets no email" do
    @user.update_columns(confirmed_at: nil)

    assert_no_emails do
      post api_v1_auth_password_path, params: { email: @user.email }
    end

    assert_response :accepted
  end

  test "blank email is a 422" do
    post api_v1_auth_password_path, params: { email: " " }

    assert_response :unprocessable_entity
    assert_equal I18n.t("api.errors.email_required"), response.parsed_body["error"]
  end

  test "unknown organization is a 401" do
    host! "no-such-org.example.com"

    assert_no_emails do
      post api_v1_auth_password_path, params: { email: @user.email }
    end

    assert_response :unauthorized
  end
end
