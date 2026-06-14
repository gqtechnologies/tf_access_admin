# frozen_string_literal: true

require "test_helper"

class Admin::ResidentialProperties::UnitOwnershipsRoutingTest < ActionDispatch::IntegrationTest
  test "POST ownerships maps to create action" do
    assert_routing(
      { method: "post", path: "/admin/residential_properties/rp-id/units/unit-id/ownerships" },
      controller: "admin/residential_properties/unit_ownerships",
      action: "create",
      residential_property_id: "rp-id",
      unit_id: "unit-id"
    )
  end

  test "PATCH ownership maps to update action" do
    assert_routing(
      { method: "patch", path: "/admin/residential_properties/rp-id/units/unit-id/ownerships/ownership-id" },
      controller: "admin/residential_properties/unit_ownerships",
      action: "update",
      residential_property_id: "rp-id",
      unit_id: "unit-id",
      id: "ownership-id"
    )
  end

  test "DELETE ownership maps to destroy action" do
    assert_routing(
      { method: "delete", path: "/admin/residential_properties/rp-id/units/unit-id/ownerships/ownership-id" },
      controller: "admin/residential_properties/unit_ownerships",
      action: "destroy",
      residential_property_id: "rp-id",
      unit_id: "unit-id",
      id: "ownership-id"
    )
  end
end
