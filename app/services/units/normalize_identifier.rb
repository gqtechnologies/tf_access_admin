# frozen_string_literal: true

module Units
  # Canonical identifier normalization for units (improve-units-foundation §2.1).
  #
  # Single source of truth for model, services, bulk import, search and backfill.
  # Pure: no database queries, no side effects.
  #
  # Returns a frozen struct with +identifier+ (trimmed, presentation-safe) and
  # +normalized_identifier+ (case-folded, hyphenated). Returns +nil+ when the
  # input is blank or whitespace-only.
  NormalizeIdentifierResult = Data.define(:identifier, :normalized_identifier)

  class NormalizeIdentifier
    def self.call(raw)
      trimmed = raw.to_s.strip
      return nil if trimmed.empty?

      new(trimmed).call
    end

    def initialize(trimmed)
      @trimmed = trimmed
    end

    def call
      NormalizeIdentifierResult.new(
        identifier: @trimmed,
        normalized_identifier: AlphanumericHyphenCodeValidatable.normalize_identifier(@trimmed)
      )
    end
  end
end
