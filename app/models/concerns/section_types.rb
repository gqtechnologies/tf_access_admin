# frozen_string_literal: true

# Allowed +property_sections.section_type+ values (string-backed).
module SectionTypes
  BLOCK       = "block"
  TOWER       = "tower"
  FLOOR       = "floor"
  PARKING     = "parking"
  STORAGE     = "storage"
  COMMERCIAL  = "commercial"
  AMENITIES   = "amenities"
  ENTRANCE    = "entrance"
  GARDEN      = "garden"
  OTHER       = "other"

  ALL = [
    BLOCK,
    TOWER,
    FLOOR,
    PARKING,
    STORAGE,
    COMMERCIAL,
    AMENITIES,
    ENTRANCE,
    GARDEN,
    OTHER
  ].freeze
end
