# frozen_string_literal: true

# Valida que un adjunto sea imagen PNG, JPEG o WebP (MIME y, en casos borde, extensión).
module AttachmentImageFormat
  module_function

  ALLOWED_CONTENT_TYPES = %w[
    image/png
    image/jpeg
    image/webp
  ].freeze

  ALLOWED_EXTENSIONS = %w[.png .jpg .jpeg .webp].freeze

  # @param source [ActiveStorage::Attached::One, ActiveStorage::Blob, ActiveStorage::Attachment,
  #   ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile, nil]
  # @return [Boolean]
  def allowed?(source)
    content_type, filename = extract_content_type_and_filename(source)
    normalized = normalize_content_type(content_type)
    return true if ALLOWED_CONTENT_TYPES.include?(normalized)

    fallback_extension_allowed?(normalized, filename)
  end

  def extract_content_type_and_filename(source)
    case source
    when ActiveStorage::Blob
      [ source.content_type, source.filename.to_s ]
    when ActiveStorage::Attached::One
      return [ nil, "" ] unless source.attached?

      extract_content_type_and_filename(source.blob)
    when ActiveStorage::Attachment
      extract_content_type_and_filename(source.blob)
    when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
      [ source.content_type, source.original_filename.to_s ]
    else
      [ nil, "" ]
    end
  end

  def normalize_content_type(content_type)
    ct = content_type.to_s.strip.downcase
    return "image/jpeg" if ct == "image/jpg"

    ct.presence
  end

  # Solo si el cliente no envía un MIME fiable (p. ej. application/octet-stream o vacío).
  def fallback_extension_allowed?(normalized_content_type, filename)
    return false if filename.blank?
    return false unless normalized_content_type.blank? || normalized_content_type == "application/octet-stream"

    ALLOWED_EXTENSIONS.include?(File.extname(filename).downcase)
  end
  private :fallback_extension_allowed?
end
