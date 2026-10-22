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

  APPLE_REVOCATION_TEST_KEY = OpenSSL::PKey::EC.generate("prime256v1")

  # Runs the block with SocialAuth::AppleTokenRevocation configured with a
  # throwaway key; the caller stubs Apple's endpoints with WebMock.
  def with_apple_revocation_configured(&block)
    values = {
      "APPLE_SIGN_IN_TEAM_ID" => "TEAM123456",
      "APPLE_SIGN_IN_KEY_ID" => "KEY1234567",
      "APPLE_SIGN_IN_PRIVATE_KEY" => APPLE_REVOCATION_TEST_KEY.to_pem.gsub("\n", "\\n")
    }
    previous = values.keys.index_with { |key| ENV[key] }
    ENV.update(values)
    block.call
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  def stub_apple_revocation(token_status: 200)
    token_body = token_status == 200 ? { access_token: "at", refresh_token: "rt-123", token_type: "Bearer" }.to_json : { error: "invalid_grant" }.to_json
    {
      token: stub_request(:post, "https://appleid.apple.com/auth/token").to_return(status: token_status, body: token_body),
      revoke: stub_request(:post, "https://appleid.apple.com/auth/revoke").with(body: hash_including("token" => "rt-123", "token_type_hint" => "refresh_token")).to_return(status: 200, body: "")
    }
  end
end
