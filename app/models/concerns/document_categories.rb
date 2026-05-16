# frozen_string_literal: true

# Allowed +documents.category+ values (string-backed).
module DocumentCategories
  CONTRACT       = "contract"
  ID             = "id"
  INSURANCE      = "insurance"
  INVOICE        = "invoice"
  NOTICE         = "notice"
  MEETING_MINUTES = "meeting_minutes"
  PERMIT         = "permit"
  DEED           = "deed"
  OTHER          = "other"

  ALL = [
    CONTRACT,
    ID,
    INSURANCE,
    INVOICE,
    NOTICE,
    MEETING_MINUTES,
    PERMIT,
    DEED,
    OTHER
  ].freeze
end
