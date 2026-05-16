# frozen_string_literal: true

# Allowed +people.person_type+ values (string-backed).
module PersonTypes
  NATURAL = "natural"
  LEGAL   = "legal"

  ALL = [ NATURAL, LEGAL ].freeze
end
