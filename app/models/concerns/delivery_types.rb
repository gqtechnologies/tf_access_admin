# frozen_string_literal: true

# Allowed +parcel_deliveries.delivery_type+ values (string-backed).
module DeliveryTypes
  PARCEL   = "parcel"
  FOOD     = "food"
  DOCUMENT = "document"
  GROCERIES = "groceries"
  OTHER    = "other"

  ALL = [ PARCEL, FOOD, DOCUMENT, GROCERIES, OTHER ].freeze
end
