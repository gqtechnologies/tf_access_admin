# frozen_string_literal: true

# Allowed +common_areas.area_type+ values (string-backed).
module CommonAreaTypes
  POOL            = "pool"
  GYM             = "gym"
  BBQ             = "bbq"
  MULTIPURPOSE    = "multipurpose_hall"
  MEETING_ROOM    = "meeting_room"
  COWORKING       = "coworking"
  TERRACE         = "terrace"
  SAUNA           = "sauna"
  COURT           = "court"
  PLAYGROUND      = "playground"
  GAME_ROOM       = "game_room"
  LAUNDRY         = "laundry"
  OTHER           = "other"

  ALL = [
    POOL,
    GYM,
    BBQ,
    MULTIPURPOSE,
    MEETING_ROOM,
    COWORKING,
    TERRACE,
    SAUNA,
    COURT,
    PLAYGROUND,
    GAME_ROOM,
    LAUNDRY,
    OTHER
  ].freeze
end
