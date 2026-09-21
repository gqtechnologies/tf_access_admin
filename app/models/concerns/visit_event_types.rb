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
  REJECTED = "rejected"
  # Concierge found the person at the door is not the invited visitor; status unchanged.
  ENTRY_DENIED = "entry_denied"

  MVP = [
    CREATED,
    AUTHORIZED,
    CHECKED_IN,
    CHECKED_OUT,
    CANCELLED
  ].freeze

  ALL = (MVP + [ INVITATION_RESENT, REJECTED, ENTRY_DENIED ]).freeze
end
