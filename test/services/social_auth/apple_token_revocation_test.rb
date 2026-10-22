# frozen_string_literal: true

require "test_helper"

class SocialAuth::AppleTokenRevocationTest < ActiveSupport::TestCase
  include SocialTokenTestHelper

  test "exchanges the code and revokes the refresh token with a signed client secret" do
    stubs = stub_apple_revocation

    result = with_apple_revocation_configured { SocialAuth::AppleTokenRevocation.call(authorization_code: "code-1") }

    assert result
    assert_requested(:post, "https://appleid.apple.com/auth/token") do |request|
      form = URI.decode_www_form(request.body).to_h
      secret, header = JWT.decode(form["client_secret"], SocialTokenTestHelper::APPLE_REVOCATION_TEST_KEY, true, algorithms: [ "ES256" ])
      form["code"] == "code-1" && form["client_id"] == "cl.tf-access.app" &&
        secret["iss"] == "TEAM123456" && secret["sub"] == "cl.tf-access.app" && header["kid"] == "KEY1234567"
    end
    assert_requested(stubs[:revoke])
  end

  test "does nothing until the key is configured" do
    stubs = stub_apple_revocation

    assert_not SocialAuth::AppleTokenRevocation.call(authorization_code: "code-1")
    assert_not_requested(stubs[:token])
  end

  test "a rejected code is logged, not raised" do
    stubs = stub_apple_revocation(token_status: 400)

    result = with_apple_revocation_configured { SocialAuth::AppleTokenRevocation.call(authorization_code: "expired") }

    assert_not result
    assert_not_requested(stubs[:revoke])
  end
end
