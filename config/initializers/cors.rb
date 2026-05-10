# frozen_string_literal: true

allowed_origins = ENV.fetch("API_CORS_ALLOWED_ORIGIN", "http://localhost:5100")
  .split(",")
  .map(&:strip)
  .reject(&:blank?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: %i[get post options head],
      expose: %w[Authorization],
      max_age: 600,
      credentials: false
  end
end
