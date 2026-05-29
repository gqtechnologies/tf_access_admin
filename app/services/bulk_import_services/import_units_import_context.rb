# frozen_string_literal: true

module BulkImportServices
  class ImportUnitsImportContext
    include OwnerImportMode

    attr_reader :bulk_import, :owner_import_mode

    def initialize(bulk_import:)
      @bulk_import = bulk_import
      options = bulk_import.metadata.fetch("options", {})
      @owner_import_mode = OwnerImportMode.resolve(options["owner_import_mode"])
      @people_by_digest = {}
      @people_by_email = {}
    end

    def cached_person_for(normalized)
      person = person_from_cache(normalized)
      return person if person

      person = ResolveImportOwnerPerson.find_existing(
        organization: @bulk_import.organization,
        normalized:
      )
      cache_person!(normalized, person) if person
      person
    end

    def resolve_person!(normalized)
      cached = cached_person_for(normalized)
      return cached if cached

      person = ResolveImportOwnerPerson.call(
        context: self,
        normalized:
      )
      cache_person!(normalized, person) if person
      person
    end

    def cache_person!(normalized, person)
      digest = owner_document_digest(normalized)
      @people_by_digest[digest] = person if digest.present?

      email = owner_email(normalized)
      @people_by_email[email] = person if email.present?
    end

    def person_from_cache(normalized)
      digest = owner_document_digest(normalized)
      return @people_by_digest[digest] if digest.present? && @people_by_digest.key?(digest)

      email = owner_email(normalized)
      @people_by_email[email] if email.present? && @people_by_email.key?(email)
    end

    def owner_document_digest(normalized)
      document = normalized["owner_document"]&.downcase&.strip
      return nil if document.blank?

      UnitsImportValidationContext.document_digest(document)
    end

    def owner_email(normalized)
      normalized["owner_email"]&.downcase&.strip.presence
    end
  end
end
