# frozen_string_literal: true

# Allowed +residential_properties.property_type+ values (string-backed).
module PropertyTypes
  BUILDING            = "building"
  CONDOMINIUM         = "condominium"
  HORIZONTAL          = "horizontal_community"
  RESIDENTIAL_COMPLEX = "residential_complex"
  MIXED_USE           = "mixed_use"
  TOWER               = "tower"
  SECTOR              = "sector"
  OTHER               = "other"

  ALL = [
    BUILDING,
    CONDOMINIUM,
    HORIZONTAL,
    RESIDENTIAL_COMPLEX,
    MIXED_USE,
    TOWER,
    SECTOR,
    OTHER
  ].freeze
end
