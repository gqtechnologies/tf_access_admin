# frozen_string_literal: true

# Allowed +incidents.category+ values (string-backed).
module IncidentCategories
  SECURITY     = "security"
  MAINTENANCE  = "maintenance"
  NOISE        = "noise"
  ACCESS       = "access"
  PARCEL       = "parcel"
  COMMON_AREA  = "common_area"
  DISPUTE      = "dispute"
  HEALTH       = "health"
  ENVIRONMENT  = "environment"
  OTHER        = "other"

  ALL = [
    SECURITY,
    MAINTENANCE,
    NOISE,
    ACCESS,
    PARCEL,
    COMMON_AREA,
    DISPUTE,
    HEALTH,
    ENVIRONMENT,
    OTHER
  ].freeze
end
