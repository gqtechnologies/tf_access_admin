# frozen_string_literal: true

# Allowed +announcements.status+ values (string-backed).
module AnnouncementStatuses
  DRAFT     = "draft"
  PUBLISHED = "published"
  ARCHIVED  = "archived"

  ALL = [ DRAFT, PUBLISHED, ARCHIVED ].freeze
end
