# frozen_string_literal: true

module SocialAuth
  # Verifies an identity token issued by Apple or Google to the mobile app:
  # RS256 signature against the provider's published keys, issuer, expiry and
  # audience. The audience check is what ties the token to *this* app — a token
  # minted for any other app is rejected.
  #
  # Audiences come from the environment:
  #   APPLE_SIGN_IN_AUDIENCES   – comma-separated bundle ids (defaults to the app's)
  #   GOOGLE_SIGN_IN_CLIENT_IDS – comma-separated OAuth client ids (no default:
  #                               Google stays disabled until it is set)
  class TokenVerifier
    class InvalidToken < StandardError; end
    class NotConfigured < StandardError; end

    Claims = Struct.new(:provider, :subject, :email, :email_verified, :name, keyword_init: true)

    PROVIDERS = {
      "apple" => {
        issuers: [ "https://appleid.apple.com" ],
        jwks_url: "https://appleid.apple.com/auth/keys",
        audiences_env: "APPLE_SIGN_IN_AUDIENCES",
        default_audiences: "cl.tf-access.app"
      },
      "google" => {
        issuers: [ "https://accounts.google.com", "accounts.google.com" ],
        jwks_url: "https://www.googleapis.com/oauth2/v3/certs",
        audiences_env: "GOOGLE_SIGN_IN_CLIENT_IDS",
        default_audiences: nil
      }
    }.freeze

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.audiences_for(provider)
      config = PROVIDERS[provider.to_s]
      return [] if config.nil?

      ENV.fetch(config[:audiences_env], config[:default_audiences].to_s).split(",").map(&:strip).compact_blank
    end

    def initialize(provider:, id_token:)
      @provider = provider.to_s
      @id_token = id_token.to_s
    end

    def call
      config = PROVIDERS[@provider]
      raise InvalidToken, "unknown provider" if config.nil? || @id_token.blank?

      audiences = self.class.audiences_for(@provider)
      raise NotConfigured, "#{@provider} sign-in has no audience configured" if audiences.empty?

      payload = decode(config, audiences)

      Claims.new(
        provider: @provider,
        subject: payload["sub"].to_s,
        email: payload["email"].to_s.downcase.strip.presence,
        email_verified: payload["email_verified"].to_s == "true",
        name: payload["name"].to_s.strip.presence
      )
    end

    private

    def decode(config, audiences)
      payload, = JWT.decode(
        @id_token, nil, true,
        algorithms: [ "RS256" ],
        iss: config[:issuers], verify_iss: true,
        aud: audiences, verify_aud: true,
        jwks: jwks_loader(config[:jwks_url])
      )
      payload
    rescue JWT::DecodeError, Jwks::FetchError => e
      raise InvalidToken, e.message
    end

    def jwks_loader(url)
      ->(options) { Jwks.fetch(url, force: options[:kid_not_found] == true) }
    end
  end
end
