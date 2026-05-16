# frozen_string_literal: true

# Allowed +authorized_residents.relationship_type+ values (string-backed).
module RelationshipTypes
  SPOUSE   = "spouse"
  CHILD    = "child"
  PARENT   = "parent"
  ROOMMATE = "roommate"
  STAFF    = "staff"
  OTHER    = "other"

  ALL = [ SPOUSE, CHILD, PARENT, ROOMMATE, STAFF, OTHER ].freeze
end
