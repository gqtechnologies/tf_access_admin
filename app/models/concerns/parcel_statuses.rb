# frozen_string_literal: true

# Allowed +parcel_deliveries.status+ values (string-backed).
module ParcelStatuses
  RECEIVED  = "received"
  WITHDRAWN = "withdrawn"

  ALL = [ RECEIVED, WITHDRAWN ].freeze
end
