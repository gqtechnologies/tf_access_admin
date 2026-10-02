# frozen_string_literal: true

require "test_helper"

class SocialAuth::TokenVerifierTest < ActiveSupport::TestCase
  include SocialTokenTestHelper

  test "verifies an Apple token and extracts the claims" do
    with_social_providers do
      claims = verify("apple", social_token("apple", email: "Ana@Example.com", email_verified: "true"))

      assert_equal "apple", claims.provider
      assert_equal "ana@example.com", claims.email
      assert claims.email_verified
      assert_nil claims.name
    end
  end

  test "verifies a Google token with its name" do
    with_social_providers do
      claims = verify("google", social_token("google", email: "beto@example.com", name: " Beto Soto "))

      assert_equal "beto@example.com", claims.email
      assert_equal "Beto Soto", claims.name
    end
  end

  test "unverified email is reported as such" do
    with_social_providers do
      assert_not verify("google", social_token("google", email: "c@example.com", email_verified: false)).email_verified
    end
  end

  test "rejects a token for another app, another issuer, expired, or signed by another key" do
    with_social_providers do
      [
        social_token("apple", email: "a@example.com", aud: "com.someone.else"),
        social_token("apple", email: "a@example.com", iss: "https://evil.example"),
        social_token("apple", email: "a@example.com", exp: 1.minute.ago.to_i),
        social_token("apple", email: "a@example.com", key: OpenSSL::PKey::RSA.new(2048)),
        "not-a-token",
        ""
      ].each do |token|
        assert_raises(SocialAuth::TokenVerifier::InvalidToken, token.first(20)) { verify("apple", token) }
      end
    end
  end

  test "rejects a Google token presented as Apple and unknown providers" do
    with_social_providers do
      google = social_token("google", email: "a@example.com")

      assert_raises(SocialAuth::TokenVerifier::InvalidToken) { verify("apple", google) }
      assert_raises(SocialAuth::TokenVerifier::InvalidToken) { verify("facebook", google) }
    end
  end

  test "rejects an unsigned token" do
    with_social_providers do
      unsigned = JWT.encode({ iss: "https://appleid.apple.com", aud: "cl.tf-access.app", email: "a@example.com" }, nil, "none")

      assert_raises(SocialAuth::TokenVerifier::InvalidToken) { verify("apple", unsigned) }
    end
  end

  test "Google is not configured without client ids" do
    with_social_providers do
      ENV["GOOGLE_SIGN_IN_CLIENT_IDS"] = ""

      assert_raises(SocialAuth::TokenVerifier::NotConfigured) do
        verify("google", social_token("google", email: "a@example.com"))
      end
    end
  end

  private

  def verify(provider, token)
    SocialAuth::TokenVerifier.call(provider: provider, id_token: token)
  end
end
