# frozen_string_literal: true

module Properties
  module Setup
    # Single source of truth for section naming: "prefix + suffix", where the
    # suffix is a letter (A, B, C…) or a number (1, 2, 3…). Shared by the quick
    # structure engine (`GenerateStructurePreview`, `ApplyQuickStructure`) and the
    # manual builder batch (`PropertySections::CreateBatch`) so every producer
    # agrees on the generated names. Mirrored on the front end in
    # `structurePreview.ts` for the manual modal's live "De creación" preview.
    #
    # +index+ is zero-based: index 0 → "A" / "1".
    class SectionNameSequence
      LETTER = :letter
      NUMBER = :number

      def self.name(prefix:, suffix_type:, index:)
        "#{prefix} #{suffix(suffix_type, index)}".strip
      end

      def self.names(prefix:, suffix_type:, count:)
        Array.new([ count.to_i, 0 ].max) do |index|
          name(prefix: prefix, suffix_type: suffix_type, index: index)
        end
      end

      def self.suffix(suffix_type, index)
        suffix_type.to_sym == LETTER ? ("A".ord + index).chr : (index + 1).to_s
      end
    end
  end
end
