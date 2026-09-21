# frozen_string_literal: true

# Functional history event types for visit lifecycle (MVP).
module VisitEventTypes
  CREATED = "created"
  AUTHORIZED = "authorized"
  CHECKED_IN = "checked_in"
  CHECKED_OUT = "checked_out"
  CANCELLED = "cancelled"
  # Resident re-sent the visitor invitation; the visit status does not change.
  INVITATION_RESENT = "invitation_resent"

  MVP = [
    CREATED,
    AUTHORIZED,
    CHECKED_IN,
    CHECKED_OUT,
    CANCELLED
  ].freeze

  ALL = (MVP + [ INVITATION_RESENT ]).freeze
end
