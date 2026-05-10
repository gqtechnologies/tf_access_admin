# frozen_string_literal: true

# URLs/paths de Active Storage para admin, serializers e Inertia.
# Acepta Blob, Attached::One o Attachment (p. ej. avatar, cover, cada foto).
module BlobUrls
  module_function

  # Absoluta si hay `default_url_options[:host]`; si no, path relativo (mismo criterio que ProductPhotos).
  def url_for(source)
    blob = resolve_blob(source)
    return nil unless blob

    routes = Rails.application.routes.url_helpers
    opts = Rails.application.routes.default_url_options.presence ||
           Rails.application.config.action_mailer.default_url_options

    if opts.present? && opts[:host].present?
      routes.rails_blob_url(
        blob,
        **opts.symbolize_keys,
        protocol: (Rails.env.production? ? "https" : "http"),
      )
    else
      routes.rails_blob_path(blob, only_path: true)
    end
  end

  def resolve_blob(source)
    case source
    when ActiveStorage::Blob then source
    when ActiveStorage::Attached::One
      source.attached? ? source.blob : nil
    when ActiveStorage::Attachment
      source.blob
    else
      nil
    end
  end
end
