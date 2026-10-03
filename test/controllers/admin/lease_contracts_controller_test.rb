# frozen_string_literal: true

require "test_helper"

# /admin/lease_contracts — OpenSpec 2026-10-02-lease-contracts.
class Admin::LeaseContractsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ReservationTestHelper

  setup do
    setup_reservation_world("LC")
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "registering a draft, activating it creates the tenant occupancy, terminating closes it" do
    sign_in_as(@property_admin)

    post admin_lease_contracts_path(property_id: @property.id), params: {
      lessee: { name: "Tomás Tenant", email: "tomas@example.test", document: "15.555.666-7" },
      lease: { unit_id: @unit.id, lessor_person_id: person_of(@owner).id, starts_at: Date.current.iso8601,
               ends_at: 1.year.from_now.to_date.iso8601, can_reserve_common_areas: false }
    }

    lease = ActsAsTenant.with_tenant(@organization) { LeaseContract.sole }
    assert_equal LeaseStatuses::DRAFT, lease.status
    assert_equal person_of(@owner).id, lease.lessor_person_id
    assert lease.can_withdraw_parcels
    assert_not lease.can_reserve_common_areas

    inertia_get admin_lease_contracts_path(property_id: @property.id, tab: "draft")
    assert_equal [ "Tomás Tenant" ], inertia_props["leases"].map { |l| l["lessee_name"] }
    assert_equal [ "Carla Owner" ], inertia_props["units"].find { |u| u["id"] == @unit.id }["owners"].map { |o| o["name"] }

    post activate_admin_lease_contract_path(lease)
    occupancy = ActsAsTenant.with_tenant(@organization) { lease.reload.occupancy }
    assert_equal LeaseStatuses::ACTIVE, lease.status
    assert_equal OccupancyTypes::TENANT, occupancy.occupancy_type
    assert_equal lease.lessee_person_id, occupancy.person_id
    assert occupancy.can_withdraw_parcels
    assert_not occupancy.can_reserve_common_areas
    assert ActsAsTenant.with_tenant(@organization) { Authorization::ActiveRelationships.active_occupancies_of_unit(@unit).exists?(id: occupancy.id) }

    post terminate_admin_lease_contract_path(lease)
    assert_equal LeaseStatuses::TERMINATED, lease.reload.status
    assert_equal Date.current, lease.ends_at
    assert occupancy.reload.ends_at <= Time.current.end_of_day + 1.day
  end

  test "a landlord who does not own the unit is refused and nothing is stored" do
    sign_in_as(@tenant_admin)

    post admin_lease_contracts_path(property_id: @property.id), params: {
      lessee: { name: "Tomás", email: "tomas2@example.test" },
      lease: { unit_id: @unit.id, lessor_person_id: person_of(@relative).id, starts_at: Date.current.iso8601 }
    }

    assert_equal 0, ActsAsTenant.with_tenant(@organization) { LeaseContract.count }
  end

  test "activating twice is refused" do
    lease = ActsAsTenant.with_tenant(@organization) do
      LeaseContracts::Create.call(unit: @unit, actor: @tenant_admin,
                                  lessee_params: { name: "Tomás", email: "tomas3@example.test" },
                                  attributes: { starts_at: Date.current })
    end
    ActsAsTenant.current_tenant = nil
    sign_in_as(@tenant_admin)

    post activate_admin_lease_contract_path(lease)
    post activate_admin_lease_contract_path(lease)

    assert_equal 1, ActsAsTenant.with_tenant(@organization) { UnitOccupancy.where(source: lease).count }
  end

  test "concierge and residents are redirected away" do
    [ @concierge, @relative ].each do |user|
      sign_in_as(user)
      get admin_lease_contracts_path

      assert_response :redirect
    end
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
