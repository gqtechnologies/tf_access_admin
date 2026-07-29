# frozen_string_literal: true

require "test_helper"

class Api::V1::Mobile::MeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = organizations(:one)
    @user = create_user_for_organization(
      organization: @organization,
      email: "mobile-me@example.com",
      role: AvailableRoles::CLIENT
    )
  end

  test "authenticated user fetches their profile" do
    sign_in @user

    get api_v1_mobile_me_path

    assert_response :ok
    body = response.parsed_body
    assert_equal @user.email, body.dig("data", "email")
    assert_equal @user.name, body.dig("data", "name")
    assert_equal @user.dni, body.dig("data", "dni")
  end

  test "unauthenticated request is rejected" do
    get api_v1_mobile_me_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end
end
