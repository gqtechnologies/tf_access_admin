# frozen_string_literal: true

require "test_helper"

class Admin::ResidentialProperties::UnitOccupanciesRoutingTest < ActionDispatch::IntegrationTest
  test "POST occupancies maps to create action" do
    assert_routing(
      { method: "post", path: "/admin/residential_properties/rp-id/units/unit-id/occupancies" },
      controller: "admin/residential_properties/unit_occupancies",
      action: "create",
      residential_property_id: "rp-id",
      unit_id: "unit-id"
    )
  end

  test "PATCH occupancy maps to update action" do
    assert_routing(
      { method: "patch", path: "/admin/residential_properties/rp-id/units/unit-id/occupancies/occupancy-id" },
      controller: "admin/residential_properties/unit_occupancies",
      action: "update",
      residential_property_id: "rp-id",
      unit_id: "unit-id",
      id: "occupancy-id"
    )
  end

  test "DELETE occupancy maps to destroy action" do
    assert_routing(
      { method: "delete", path: "/admin/residential_properties/rp-id/units/unit-id/occupancies/occupancy-id" },
      controller: "admin/residential_properties/unit_occupancies",
      action: "destroy",
      residential_property_id: "rp-id",
      unit_id: "unit-id",
      id: "occupancy-id"
    )
  end
end
