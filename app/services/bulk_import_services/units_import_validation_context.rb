# frozen_string_literal: true

module BulkImportServices
  class UnitsImportValidationContext
    attr_reader :import_mode, :owner_import_mode, :property_section_id, :residential_property

    def initialize(bulk_import:)
      @bulk_import = bulk_import
      options = bulk_import.metadata.fetch("options", {})
      @import_mode = options["import_mode"] || CreateUnitsImport::IMPORT_MODES[:create_skip_duplicates]
      @owner_import_mode = resolve_owner_import_mode(options)
      @property_section_id = resolve_property_section_id_option(options)
      @residential_property = bulk_import.residential_property
      @existing_unit_keys = load_existing_unit_keys
      @seen_uniqueness_keys = Hash.new(0)
      @group_percentages = Hash.new(0.0)
      load_owner_lookup_index
    end

    def ignore_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:ignore]
    end

    def link_existing_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:link_existing]
    end

    def create_missing_owners?
      owner_import_mode == CreateUnitsImport::OWNER_IMPORT_MODES[:create_missing]
    end

    def process_owners?
      !ignore_owners?
    end

    def owner_exists?(normalized)
      document = normalized["owner_document"]&.downcase&.strip
      if document.present?
        digest = self.class.document_digest(document)
        return true if @owner_document_digests.include?(digest)
      end

      email = normalized["owner_email"]&.downcase&.strip
      return true if email.present? && @owner_emails.include?(email)

      # name = normalized["owner_name"]&.downcase&.strip
      # return true if name.present? && @owner_names.include?(normalize_owner_key(name))

      false
    end

    def self.document_digest(document_number)
      normalized = document_number.to_s.downcase.gsub(/[^a-z0-9]/, "")
      Digest::SHA256.hexdigest(normalized)
    end

    def existing_unit?(property_section_id, unit_identifier)
      return false if property_section_id.blank? || unit_identifier.blank?

      normalized = normalize_identifier(unit_identifier)
      @existing_unit_keys.include?([ property_section_id, normalized ])
    end

    def register_uniqueness_key!(key)
      @seen_uniqueness_keys[key] += 1
    end

    def duplicate_in_file?(key)
      @seen_uniqueness_keys[key] > 1
    end

    def add_group_percentage(group_key, percentage)
      return if group_key.blank? || percentage.nil?

      @group_percentages[group_key] += percentage.to_f
    end

    def group_percentage_exceeded?(group_key)
      (@group_percentages[group_key] || 0) > 100.0
    end

    def skip_duplicates?
      import_mode == CreateUnitsImport::IMPORT_MODES[:create_skip_duplicates]
    end

    def uniqueness_key(property_section_id, unit_identifier, owner_fingerprint)
      group_key = build_group_key(property_section_id, unit_identifier)
      return nil if group_key.nil?

      "#{group_key}:#{owner_fingerprint}"
    end

    def build_group_key(property_section_id, unit_identifier)
      return nil if property_section_id.blank? || unit_identifier.blank?

      "unit:#{property_section_id}:#{normalize_identifier(unit_identifier)}"
    end

    private

    def resolve_property_section_id_option(options)
      options["property_section_id"].presence ||
        @bulk_import.property_section_id
    end

    def resolve_owner_import_mode(options)
      mode = options["owner_import_mode"]
      return mode if CreateUnitsImport::OWNER_IMPORT_MODES.value?(mode)

      CreateUnitsImport::OWNER_IMPORT_MODES[:ignore]
    end

    def load_owner_lookup_index
      people = Person.where(organization_id: @bulk_import.organization_id)

      @owner_document_digests = people.pluck(:document_number_digest).compact.to_set
      @owner_names = people.pluck(:display_name).filter_map { |name| normalize_owner_key(name) }.to_set
      @owner_emails = people.joins(:user)
        .where.not(users: { email: nil })
        .pluck("users.email")
        .map { |email| email.downcase.strip }
        .to_set
    end

    def normalize_owner_key(value)
      value.to_s.downcase.gsub(/\s+/, " ").strip.presence
    end

    def load_existing_unit_keys
      Unit.where(residential_property_id: @residential_property.id)
        .pluck(:property_section_id, :normalized_identifier)
        .map { |section_id, identifier| [ section_id, identifier ] }
        .to_set
    end

    def normalize_identifier(identifier)
      AlphanumericHyphenCodeValidatable.normalize_identifier(identifier)
    end
  end
end
