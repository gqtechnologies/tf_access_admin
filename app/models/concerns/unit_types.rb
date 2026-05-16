# frozen_string_literal: true

# Allowed +units.unit_type+ values (string-backed).
module UnitTypes
  APARTMENT = "apartment"
  HOUSE     = "house"
  STUDIO     = "studio"
  DUPLEX    = "duplex"
  PENTHOUSE = "penthouse"
  PARKING   = "parking"
  STORAGE   = "storage"
  COMMERCIAL = "commercial"
  OFFICE    = "office"
  WAREHOUSE = "warehouse"
  OTHER     = "other"

  ALL = [
    APARTMENT,
    HOUSE,
    STUDIO,
    DUPLEX,
    PENTHOUSE,
    PARKING,
    STORAGE,
    COMMERCIAL,
    OFFICE,
    WAREHOUSE,
    OTHER
  ].freeze
end
