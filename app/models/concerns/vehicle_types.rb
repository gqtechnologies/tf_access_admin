# frozen_string_literal: true

# Allowed +vehicles.vehicle_type+ values when present (string-backed, optional column).
module VehicleTypes
  CAR        = "car"
  MOTORCYCLE = "motorcycle"
  BICYCLE    = "bicycle"
  VAN        = "van"
  TRUCK      = "truck"
  SCOOTER    = "scooter"
  OTHER      = "other"

  ALL = [ CAR, MOTORCYCLE, BICYCLE, VAN, TRUCK, SCOOTER, OTHER ].freeze
end
