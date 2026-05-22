# frozen_string_literal: true
#TODO: Translate to English and Portuguese
module BulkImportServices
  class UnitsColumnMapper
    TARGET_FIELDS = [
      { key: "section_path", required: false },
      { key: "unit_identifier", required: true },
      { key: "unit_type", required: true },
      { key: "display_name", required: false },
      { key: "area_m2", required: false },
      { key: "status", required: false },
      { key: "owner_name", required: false },
      { key: "owner_email", required: false }
    ].freeze

    HEADER_ALIASES = {
      "numero" => "unit_identifier",
      "número" => "unit_identifier",
      "identificador" => "unit_identifier",
      "numero_identificador" => "unit_identifier",
      "número_identificador" => "unit_identifier",
      "numero_/_identificador" => "unit_identifier",
      "ruta_de_seccion" => "section_path",
      "ruta_seccion" => "section_path",
      "section_path" => "section_path",
      "tipo" => "unit_type",
      "tipo_unidad" => "unit_type",
      "unit_type" => "unit_type",
      "nombre" => "display_name",
      "display_name" => "display_name",
      "area" => "area_m2",
      "area_m2" => "area_m2",
      "estado" => "status",
      "status" => "status",
      "propietario" => "owner_name",
      "owner_name" => "owner_name",
      "email_propietario" => "owner_email",
      "owner_email" => "owner_email"
    }.freeze

    def self.call(headers:)
      new(headers:).call
    end

    def initialize(headers:)
      @headers = headers
    end

    def call
      used_sources = {}

      TARGET_FIELDS.map do |field|
        source = match_source_for(field[:key], used_sources)
        used_sources[source] = true if source

        {
          "source" => source,
          "target" => field[:key],
          "required" => field[:required],
          "matched" => source.present?
        }
      end
    end

    private

    def match_source_for(target_key, used_sources)
      @headers.find do |header|
        next if used_sources[header]

        normalize_header(header) == target_key || HEADER_ALIASES[normalize_header(header)] == target_key
      end
    end

    def normalize_header(header)
      header.to_s.strip.downcase.gsub(/\s+/, "_").gsub(/[^\w]/, "_").squeeze("_").delete_suffix("_")
    end
  end
end
