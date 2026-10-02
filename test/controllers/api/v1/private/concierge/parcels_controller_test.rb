# frozen_string_literal: true

require "test_helper"

# /api/v1/private/concierge/{parcels,units} — OpenSpec 2026-10-02-parcel-deliveries.
class Api::V1::Private::Concierge::ParcelsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ParcelTestHelper
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_parcel_world("CP")
    @waiting   = create_parcel(@unit, courier_company: "Chilexpress", tracking_code: "TRK-778")
    @withdrawn = create_parcel(
      @unit, status: ParcelStatuses::WITHDRAWN, received_at: 3.days.ago, withdrawn_at: 2.days.ago,
      withdrawn_by_person: person_of(@picker)
    )
    @foreign = create_parcel(@unit_q)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── index ───────────────────────────────────────────────────────────────────

  test "index lists the waiting parcels of the operated property with counters" do
    request_as(@concierge) { get api_v1_private_concierge_parcels_path, params: { property_id: @property.id }, headers: JSON_HEADERS }

    assert_response :ok
    assert_equal [ @waiting.id ], data.map { |p| p["id"] }
    assert_equal({ "received" => 1, "withdrawn" => 1 }, response.parsed_body["counters"])
    assert_equal 1, response.parsed_body.dig("pagination", "total_count")
  end

  test "index withdrawn tab" do
    request_as(@concierge) do
      get api_v1_private_concierge_parcels_path, params: { property_id: @property.id, tab: "withdrawn" }, headers: JSON_HEADERS
    end

    assert_equal [ @withdrawn.id ], data.map { |p| p["id"] }
    assert_equal "Ana Picker", data.first["withdrawn_by_name"]
  end

  test "index searches by unit, courier and tracking code" do
    other_unit = create_unit(@property, "CP-P-999")
    other = create_parcel(other_unit)

    { "999" => [ other.id ], "chilex" => [ @waiting.id ], "trk-778" => [ @waiting.id ], "zzz" => [] }.each do |q, expected|
      request_as(@concierge) do
        get api_v1_private_concierge_parcels_path, params: { property_id: @property.id, q: q }, headers: JSON_HEADERS
      end

      assert_equal expected, data.map { |p| p["id"] }, "q=#{q}"
    end
  end

  test "index without property_id or with a property not operated is forbidden" do
    request_as(@concierge) { get api_v1_private_concierge_parcels_path, headers: JSON_HEADERS }
    assert_response :forbidden

    request_as(@concierge) { get api_v1_private_concierge_parcels_path, params: { property_id: @property_q.id }, headers: JSON_HEADERS }
    assert_response :forbidden

    request_as(@picker) { get api_v1_private_concierge_parcels_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    assert_response :forbidden
  end

  test "tenant admin operates every property" do
    admin = create_user_for_organization(
      organization: @organization, email: "cp-admin@example.test", role: AvailableRoles::TENANT_ADMIN
    )

    request_as(admin) { get api_v1_private_concierge_parcels_path, params: { property_id: @property_q.id }, headers: JSON_HEADERS }

    assert_response :ok
    assert_equal [ @foreign.id ], data.map { |p| p["id"] }
  end

  # ─── create ──────────────────────────────────────────────────────────────────

  test "create registers a parcel and notifies the unit" do
    assert_enqueued_jobs 3, only: DeliverPushNotificationJob do
      request_as(@concierge) do
        post api_v1_private_concierge_parcels_path,
          params: { property_id: @property.id, parcel: { unit_id: @unit.id, delivery_type: "document", courier_company: "DHL", notes: "Sobre" } },
          headers: JSON_HEADERS
      end
    end

    assert_response :created
    assert_equal "document", data["delivery_type"]
    assert_equal "received", data["status"]
    assert_equal "DHL", data["courier_company"]
    assert_equal @unit.id, data.dig("unit", "id")
  end

  test "create with a unit outside the property is not found" do
    assert_no_difference "ParcelDelivery.count" do
      request_as(@concierge) do
        post api_v1_private_concierge_parcels_path,
          params: { property_id: @property.id, parcel: { unit_id: @unit_q.id } }, headers: JSON_HEADERS
      end
    end

    assert_response :not_found
  end

  test "create with an invalid delivery type is unprocessable" do
    request_as(@concierge) do
      post api_v1_private_concierge_parcels_path,
        params: { property_id: @property.id, parcel: { unit_id: @unit.id, delivery_type: "piano" } }, headers: JSON_HEADERS
    end

    assert_response :unprocessable_entity
    assert response.parsed_body["error"].present?
  end

  # ─── show / withdraw ─────────────────────────────────────────────────────────

  test "show lists only residents allowed to withdraw" do
    request_as(@concierge) { get api_v1_private_concierge_parcel_path(@waiting), headers: JSON_HEADERS }

    assert_response :ok
    assert_equal [ { "id" => person_of(@picker).id, "name" => "Ana Picker", "avatar_url" => nil } ], data["eligible_withdrawers"]
  end

  test "show of another property's parcel is not found" do
    request_as(@concierge) { get api_v1_private_concierge_parcel_path(@foreign), headers: JSON_HEADERS }

    assert_response :not_found
  end

  test "withdraw by an eligible resident" do
    request_as(@concierge) do
      post withdraw_api_v1_private_concierge_parcel_path(@waiting), params: { person_id: person_of(@picker).id }, headers: JSON_HEADERS
    end

    assert_response :ok
    assert_equal "withdrawn", data["status"]
    assert_equal "Ana Picker", data["withdrawn_by_name"]
    assert_empty data["eligible_withdrawers"]
    assert_equal ParcelStatuses::WITHDRAWN, @waiting.reload.status
  end

  test "withdraw by someone without the permission is unprocessable" do
    request_as(@concierge) do
      post withdraw_api_v1_private_concierge_parcel_path(@waiting), params: { person_id: person_of(@relative).id }, headers: JSON_HEADERS
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("api.parcels.not_eligible"), response.parsed_body["error"]
    assert_equal ParcelStatuses::RECEIVED, @waiting.reload.status
  end

  test "withdraw of an already withdrawn parcel is unprocessable" do
    request_as(@concierge) do
      post withdraw_api_v1_private_concierge_parcel_path(@withdrawn), params: { person_id: person_of(@picker).id }, headers: JSON_HEADERS
    end

    assert_response :unprocessable_entity
    assert_equal I18n.t("api.parcels.not_waiting"), response.parsed_body["error"]
  end

  test "resident cannot reach a parcel through the concierge routes" do
    request_as(@picker) do
      post withdraw_api_v1_private_concierge_parcel_path(@waiting), params: { person_id: person_of(@picker).id }, headers: JSON_HEADERS
    end

    assert_response :not_found
  end

  # ─── units picker ────────────────────────────────────────────────────────────

  test "units lists and filters the property's units" do
    create_unit(@property, "CP-P-202").update!(display_name: "Depto 202")

    request_as(@concierge) { get api_v1_private_concierge_units_path, params: { property_id: @property.id }, headers: JSON_HEADERS }
    assert_response :ok
    assert_equal [ "CP-P-101", "Depto 202" ], data.map { |u| u["name"] }

    request_as(@concierge) { get api_v1_private_concierge_units_path, params: { property_id: @property.id, q: "depto" }, headers: JSON_HEADERS }
    assert_equal [ "Depto 202" ], data.map { |u| u["name"] }

    request_as(@concierge) { get api_v1_private_concierge_units_path, params: { property_id: @property_q.id }, headers: JSON_HEADERS }
    assert_response :forbidden
  end

  private

  def data
    response.parsed_body["data"]
  end

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
