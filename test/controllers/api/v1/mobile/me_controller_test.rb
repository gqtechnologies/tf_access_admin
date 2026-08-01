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

  test "unset fields render as null" do
    sign_in @user

    get api_v1_mobile_me_path

    assert_response :ok
    body = response.parsed_body
    assert_nil body.dig("data", "phone")
    assert_nil body.dig("data", "dateOfBirth")
    assert_nil body.dig("data", "gender")
  end

  test "unauthenticated request is rejected" do
    get api_v1_mobile_me_path, headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "authenticated user updates their profile" do
    sign_in @user

    patch api_v1_mobile_me_path,
          params: {
            name: "Samuel Gomez",
            phone: { countryCode: "+56", number: "912345678" },
            dateOfBirth: "1990-01-01",
            gender: "female"
          }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :ok
    body = response.parsed_body
    assert_equal "Samuel Gomez", body.dig("data", "name")
    assert_equal({ "countryCode" => "+56", "number" => "912345678" }, body.dig("data", "phone"))
    assert_equal "1990-01-01", body.dig("data", "dateOfBirth")
    assert_equal "female", body.dig("data", "gender")

    @user.reload
    assert_equal "+56", @user.phone_country_code
    assert_equal "912345678", @user.phone_number
  end

  test "explicit null phone clears stored phone" do
    @user.update!(phone_country_code: "+56", phone_number: "912345678")
    sign_in @user

    patch api_v1_mobile_me_path,
          params: { name: @user.name, phone: nil, dateOfBirth: nil, gender: nil }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :ok
    assert_nil response.parsed_body.dig("data", "phone")

    @user.reload
    assert_nil @user.phone_country_code
    assert_nil @user.phone_number
  end

  test "invalid gender is rejected" do
    sign_in @user

    patch api_v1_mobile_me_path,
          params: { name: @user.name, gender: "not-a-real-gender" }.to_json,
          headers: { "Content-Type" => "application/json" }

    assert_response :unprocessable_entity
    assert_nil @user.reload.gender
  end

  test "unauthenticated update is rejected" do
    patch api_v1_mobile_me_path,
          params: { name: "Nope" }.to_json,
          headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :unauthorized
  end
end
