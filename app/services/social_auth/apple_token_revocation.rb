# frozen_string_literal: true

require "net/http"

module SocialAuth
  # Revokes the user's Sign in with Apple authorization when they delete their
  # account, as App Store Review Guideline 5.1.1(v) requires: Access 24 leaves
  # the user's "Apps using Apple ID" list and Apple stops relaying mail to a
  # hidden address.
  #
  # The app sends a fresh +authorization_code+ (it asks Apple again right before
  # deleting), which is exchanged for a refresh token and revoked right away, so
  # no Apple token is ever stored.
  #
  # Configured from the environment; until all three are set it does nothing:
  #   APPLE_SIGN_IN_TEAM_ID     – Apple Developer team id
  #   APPLE_SIGN_IN_KEY_ID      – id of the Sign in with Apple key
  #   APPLE_SIGN_IN_PRIVATE_KEY – contents of that key's .p8 file (PEM; "\n"
  #                               escapes are accepted for single-line values)
  # The client id is the first of APPLE_SIGN_IN_AUDIENCES (the bundle id).
  #
  # Never raises: the account is already deleted by the time this runs, so a
  # failure is logged and the deletion stands.
  class AppleTokenRevocation
    BASE_URL = "https://appleid.apple.com"
    TIMEOUT = 5

    class Failed < StandardError; end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def self.configured?
      %w[APPLE_SIGN_IN_TEAM_ID APPLE_SIGN_IN_KEY_ID APPLE_SIGN_IN_PRIVATE_KEY].all? { |key| ENV[key].present? } &&
        client_id.present?
    end

    def self.client_id
      TokenVerifier.audiences_for("apple").first
    end

    def initialize(authorization_code:)
      @authorization_code = authorization_code.to_s
    end

    # true when Apple confirmed the revocation; false otherwise.
    def call
      return false if @authorization_code.blank?

      unless self.class.configured?
        Rails.logger.warn("[AppleTokenRevocation] skipped: Sign in with Apple key not configured")
        return false
      end

      tokens = post("/auth/token", grant_type: "authorization_code", code: @authorization_code)
      token, hint = tokens["refresh_token"].present? ? [ tokens["refresh_token"], "refresh_token" ] : [ tokens["access_token"], "access_token" ]
      raise Failed, "token response without a token" if token.blank?

      post("/auth/revoke", token: token, token_type_hint: hint)
      true
    rescue Failed, JSON::ParserError, OpenSSL::PKey::PKeyError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      Rails.logger.error("[AppleTokenRevocation] failed: #{e.class}: #{e.message}")
      false
    end

    private

    def post(path, **form)
      uri = URI.parse("#{BASE_URL}#{path}")
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(form.merge(client_id: self.class.client_id, client_secret: client_secret))

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.request(request)
      end
      raise Failed, "#{path} responded #{response.code}: #{response.body.to_s.truncate(200)}" unless response.is_a?(Net::HTTPSuccess)

      response.body.present? ? JSON.parse(response.body) : {}
    end

    # The short-lived ES256 JWT Apple takes as the client secret.
    def client_secret
      @client_secret ||= begin
        now = Time.current.to_i
        JWT.encode(
          { iss: ENV.fetch("APPLE_SIGN_IN_TEAM_ID"), iat: now, exp: now + 300, aud: BASE_URL, sub: self.class.client_id },
          OpenSSL::PKey::EC.new(ENV.fetch("APPLE_SIGN_IN_PRIVATE_KEY").gsub("\\n", "\n")),
          "ES256",
          kid: ENV.fetch("APPLE_SIGN_IN_KEY_ID")
        )
      end
    end
  end
end
