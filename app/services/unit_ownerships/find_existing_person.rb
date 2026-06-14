# frozen_string_literal: true

module UnitOwnerships
  class FindExistingPerson
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(organization:, document_number: nil, email: nil)
      @organization = organization
      @document_number = document_number
      @email = email
    end

    def call
      find_by_document_digest || find_by_normalized_email
    end

    private

    def find_by_document_digest
      digest = Person.document_digest(@document_number)
      return nil if digest.blank?

      Person.find_by(organization_id: @organization.id, document_number_digest: digest)
    end

    def find_by_normalized_email
      normalized = @email.to_s.downcase.strip.presence
      return nil if normalized.blank?

      user = User.where("LOWER(email) = ?", normalized).first
      person = user&.person_for(@organization)
      return person if person

      Person.where(organization_id: @organization.id)
        .where("metadata->>'import_email' = ?", normalized)
        .first
    end
  end
end
