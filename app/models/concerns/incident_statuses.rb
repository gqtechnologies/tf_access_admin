# frozen_string_literal: true

# Allowed +incidents.status+ values (string-backed).
module IncidentStatuses
  OPEN        = "open"
  IN_PROGRESS = "in_progress"
  RESOLVED    = "resolved"
  DISMISSED   = "dismissed"

  ALL = [ OPEN, IN_PROGRESS, RESOLVED, DISMISSED ].freeze

  # Still being worked on.
  ACTIVE = [ OPEN, IN_PROGRESS ].freeze
  # Closing an incident requires a written resolution.
  CLOSED = [ RESOLVED, DISMISSED ].freeze
end
