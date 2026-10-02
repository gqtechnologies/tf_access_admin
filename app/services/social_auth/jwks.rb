# frozen_string_literal: true

require "net/http"

module SocialAuth
  # Fetches and caches an identity provider's public signing keys (JWKS).
  module Jwks
    CACHE_TTL = 1.hour
    TIMEOUT = 5

    class FetchError < StandardError; end

    module_function

    # Returns the parsed JWKS hash ({ "keys" => [...] }). +force+ skips the
    # cache — used when a token names a key id the cached set doesn't have,
    # which is what a provider's key rotation looks like.
    def fetch(url, force: false)
      Rails.cache.delete(cache_key(url)) if force

      Rails.cache.fetch(cache_key(url), expires_in: CACHE_TTL) { download(url) }
    end

    def download(url)
      uri = URI.parse(url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
        http.get(uri.request_uri)
      end
      raise FetchError, "JWKS responded #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      raise FetchError, "#{e.class}: #{e.message}"
    end

    def cache_key(url)
      "social_auth/jwks/#{url}"
    end
  end
end
