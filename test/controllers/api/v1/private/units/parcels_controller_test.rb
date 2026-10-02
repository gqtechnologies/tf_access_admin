# frozen_string_literal: true

require "test_helper"

# GET /api/v1/private/units/:unit_id/parcels — OpenSpec 2026-10-02-parcel-deliveries.
class Api::V1::Private::Units::ParcelsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ParcelTestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    setup_parcel_world("UP")
    @waiting_old = create_parcel(@unit, received_at: 2.days.ago, courier_company: "Correos")
    @waiting_new = create_parcel(@unit, received_at: 1.hour.ago, delivery_type: DeliveryTypes::FOOD)
    @withdrawn   = create_parcel(
      @unit, status: ParcelStatuses::WITHDRAWN, received_at: 5.days.ago, withdrawn_at: 4.days.ago,
      withdrawn_by_person: person_of(@picker)
    )
    create_parcel(@unit, status: ParcelStatuses::WITHDRAWN, received_at: 60.days.ago, withdrawn_at: 45.days.ago)
    create_parcel(@unit_q)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "resident sees waiting parcels first, then recent withdrawals" do
    get_parcels(@relative)

    assert_response :ok
    body = response.parsed_body
    assert_equal [ @waiting_new.id, @waiting_old.id, @withdrawn.id ], body["data"].map { |p| p["id"] }
    assert_equal false, body["can_withdraw"]

    first = body["data"].first
    assert_equal "food", first["delivery_type"]
    assert_equal "received", first["status"]
    assert_equal({ "id" => @unit.id, "name" => "UP-P-101" }, first["unit"])
    assert_equal "Ana Picker", body["data"].last["withdrawn_by_name"]
    assert_equal "Correos", body["data"].second["courier_company"]
  end

  test "can_withdraw is true for a resident with the permission" do
    get_parcels(@picker)

    assert_equal true, response.parsed_body["can_withdraw"]
  end

  test "owner without occupancy sees the parcels but cannot withdraw" do
    get_parcels(@owner)

    assert_response :ok
    assert_equal 3, response.parsed_body["data"].size
    assert_equal false, response.parsed_body["can_withdraw"]
  end

  test "member without a relationship with the unit is forbidden" do
    get_parcels(parcel_member("up-stranger@example.test", "Stranger"))

    assert_response :forbidden
  end

  test "unit of another organization is not found" do
    other_org = organizations(:two)
    foreign_unit = ActsAsTenant.with_tenant(other_org) do
      create_unit(create_property(other_org, "UP Foreign"), "UP-FX-1")
    end

    get_parcels(@picker, unit: foreign_unit)

    assert_response :not_found
  end

  test "requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_unit_parcels_path(@unit), headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  private

  def get_parcels(user, unit: @unit)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    get api_v1_private_unit_parcels_path(unit), headers: { "Accept" => "application/json" }
    sign_out user
  end
end
