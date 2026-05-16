# frozen_string_literal: true

# Allowed +announcements.category+ values when set (nullable column).
module AnnouncementCategories
  GENERAL      = "general"
  MAINTENANCE  = "maintenance"
  SECURITY     = "security"
  COMMUNITY    = "community"
  EMERGENCY    = "emergency"
  OTHER        = "other"

  ALL = [ GENERAL, MAINTENANCE, SECURITY, COMMUNITY, EMERGENCY, OTHER ].freeze
end
