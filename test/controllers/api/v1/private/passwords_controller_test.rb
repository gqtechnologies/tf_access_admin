# frozen_string_literal: true

require "test_helper"

# PATCH /api/v1/private/me/password — OpenSpec 2026-10-02-mobile-change-password.
class Api::V1::Private::PasswordsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  CURRENT = "Password1@"
  NEW = "NewPassw0rd."

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    @user = create_user_for_organization(
      organization: @organization, email: "api-change-password@example.test", role: AvailableRoles::CLIENT
    )
    ActsAsTenant.current_tenant = nil
    host! "#{@organization.subdomain}.example.com"
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "changes the password with the right current one" do
    change(current_password: CURRENT, password: NEW)

    assert_response :no_content
    assert @user.reload.valid_password?(NEW)
    assert_not @user.valid_password?(CURRENT)
  end

  test "the new password works to log in" do
    change(current_password: CURRENT, password: NEW)

    post api_v1_auth_login_path, params: { email: @user.email, password: NEW }
    assert_response :ok

    post api_v1_auth_login_path, params: { email: @user.email, password: CURRENT }
    assert_response :unauthorized
  end

  test "wrong current password is rejected on that field" do
    change(current_password: "Nope1234@", password: NEW)

    assert_response :unprocessable_entity
    assert_equal "current_password", response.parsed_body["field"]
    assert_equal I18n.t("api.password.wrong_current"), response.parsed_body["error"]
    assert @user.reload.valid_password?(CURRENT)
  end

  test "missing current password is rejected" do
    change(password: NEW)

    assert_response :unprocessable_entity
    assert_equal "current_password", response.parsed_body["field"]
  end

  test "weak new password is rejected on that field" do
    [ "short1@", "alllowercase1@", "NoSymbol123", "" ].each do |weak|
      change(current_password: CURRENT, password: weak)

      assert_response :unprocessable_entity, weak
      assert_equal "password", response.parsed_body["field"]
      assert_equal I18n.t("api.password.weak"), response.parsed_body["error"]
    end

    assert @user.reload.valid_password?(CURRENT)
  end

  test "new password equal to the current one is rejected" do
    change(current_password: CURRENT, password: CURRENT)

    assert_response :unprocessable_entity
    assert_equal "password", response.parsed_body["field"]
    assert_equal I18n.t("api.password.same_as_current"), response.parsed_body["error"]
  end

  test "requires authentication" do
    patch api_v1_private_me_password_path, params: { current_password: CURRENT, password: NEW },
      headers: { "Accept" => "application/json" }

    assert_response :unauthorized
    assert @user.reload.valid_password?(CURRENT)
  end

  private

  def change(params)
    sign_in @user
    patch api_v1_private_me_password_path, params: params, headers: { "Accept" => "application/json" }
    sign_out @user
  end
end
