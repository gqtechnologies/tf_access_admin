# frozen_string_literal: true

# Mints Apple/Google-shaped identity tokens signed with a throwaway RSA key and
# serves that key as the provider's JWKS, so SocialAuth::TokenVerifier runs for
# real (signature, issuer, audience, expiry) without touching the network.
module SocialTokenTestHelper
  SOCIAL_TEST_KEY = OpenSSL::PKey::RSA.new(2048)
  SOCIAL_TEST_JWK = JWT::JWK.new(SOCIAL_TEST_KEY, kid: "test-key")
  GOOGLE_TEST_CLIENT_ID = "test-client.apps.googleusercontent.com"

  ISSUERS = { "apple" => "https://appleid.apple.com", "google" => "https://accounts.google.com" }.freeze
  AUDIENCES = { "apple" => "cl.tf-access.app", "google" => GOOGLE_TEST_CLIENT_ID }.freeze

  def social_token(provider, email:, key: SOCIAL_TEST_KEY, **overrides)
    payload = {
      iss: ISSUERS.fetch(provider),
      aud: AUDIENCES.fetch(provider),
      sub: "sub-#{email}",
      email: email,
      email_verified: true,
      iat: Time.current.to_i,
      exp: 10.minutes.from_now.to_i
    }.merge(overrides)

    JWT.encode(payload.compact, key, "RS256", kid: "test-key")
  end

  # Runs the block with the test key published as every provider's JWKS and
  # Google configured with the test client id.
  def with_social_providers(&block)
    jwks = { "keys" => [ SOCIAL_TEST_JWK.export.stringify_keys ] }
    previous = ENV["GOOGLE_SIGN_IN_CLIENT_IDS"]
    ENV["GOOGLE_SIGN_IN_CLIENT_IDS"] = GOOGLE_TEST_CLIENT_ID

    # Minitest 6 ships without minitest/mock, so swap the singleton method by hand.
    original = SocialAuth::Jwks.method(:fetch)
    SocialAuth::Jwks.define_singleton_method(:fetch) { |*_args, **_kwargs| jwks }

    block.call
  ensure
    SocialAuth::Jwks.define_singleton_method(:fetch, original) if original
    ENV["GOOGLE_SIGN_IN_CLIENT_IDS"] = previous
  end
end
