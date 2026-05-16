# frozen_string_literal: true

# Allowed +documents.visibility+ values (string-backed).
module DocumentVisibilities
  PRIVATE   = "private"
  RESIDENTS = "residents"
  STAFF     = "staff"
  PUBLIC    = "public"

  ALL = [ PRIVATE, RESIDENTS, STAFF, PUBLIC ].freeze
end
