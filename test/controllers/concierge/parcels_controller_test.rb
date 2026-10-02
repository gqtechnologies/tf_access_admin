# frozen_string_literal: true

require "test_helper"

# Web front-desk parcels — OpenSpec 2026-10-02-parcels-web.
class Concierge::ParcelsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper
  include ParcelTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_parcel_world("WP")
    @waiting   = create_parcel(@unit, courier_company: "Starken")
    @withdrawn = create_parcel(
      @unit, status: ParcelStatuses::WITHDRAWN, received_at: 3.days.ago, withdrawn_at: 2.days.ago,
      withdrawn_by_person: person_of(@picker)
    )
    @foreign = create_parcel(@unit_q)
    @tenant_admin = create_user_for_organization(
      organization: @organization, email: "wp-admin@example.test", role: AvailableRoles::TENANT_ADMIN
    )
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── index ───────────────────────────────────────────────────────────────────

  test "concierge sees the waiting parcels of the assigned property" do
    sign_in_as(@concierge)
    inertia_get concierge_parcels_path

    assert_response :success
    assert_equal "concierge/parcels/index", inertia_component

    props = inertia_props
    assert_equal [ @waiting.id ], props["parcels"].map { |p| p["id"] }
    assert_equal({ "received" => 1, "withdrawn" => 1 }, props["counters"])
    assert_equal @property.id, props.dig("active_property", "id")
    assert_equal [ @property.id ], props["properties"].map { |p| p["id"] }
    assert_equal [ "WP-P-101" ], props["units"].map { |u| u["name"] }
    assert_equal [ { "id" => person_of(@picker).id, "name" => "Ana Picker" } ],
      props["parcels"].first["eligible_withdrawers"]
    assert_equal DeliveryTypes::ALL, props["delivery_types"]
  end

  test "withdrawn tab and search" do
    sign_in_as(@concierge)

    inertia_get concierge_parcels_path(tab: "withdrawn")
    assert_equal [ @withdrawn.id ], inertia_props["parcels"].map { |p| p["id"] }
    assert_equal "Ana Picker", inertia_props["parcels"].first["withdrawn_by_name"]
    assert_empty inertia_props["parcels"].first["eligible_withdrawers"]

    inertia_get concierge_parcels_path(q: { query: "stark" })
    assert_equal [ @waiting.id ], inertia_props["parcels"].map { |p| p["id"] }

    inertia_get concierge_parcels_path(q: { query: "nothing" })
    assert_empty inertia_props["parcels"]
  end

  test "concierge cannot pin a property they do not operate" do
    sign_in_as(@concierge)
    inertia_get concierge_parcels_path(property_id: @property_q.id)

    assert_equal @property.id, inertia_props.dig("active_property", "id")
    assert_equal [ @waiting.id ], inertia_props["parcels"].map { |p| p["id"] }
  end

  test "tenant admin can switch between every property" do
    sign_in_as(@tenant_admin)
    inertia_get concierge_parcels_path(property_id: @property_q.id)

    assert_response :success
    assert_equal [ @foreign.id ], inertia_props["parcels"].map { |p| p["id"] }
    assert_includes inertia_props["properties"].map { |p| p["id"] }, @property.id
  end

  test "resident is redirected away" do
    sign_in_as(@picker)
    get concierge_parcels_path

    assert_response :redirect
  end

  # ─── create ──────────────────────────────────────────────────────────────────

  test "create registers the parcel and notifies the unit" do
    sign_in_as(@concierge)

    assert_difference "ParcelDelivery.count", 1 do
      assert_enqueued_jobs 3, only: DeliverPushNotificationJob do
        post concierge_parcels_path, params: {
          property_id: @property.id,
          parcel: { unit_id: @unit.id, delivery_type: "groceries", courier_company: "Jumbo", notes: "2 bolsas" }
        }
      end
    end

    assert_redirected_to concierge_parcels_path(property_id: @property.id)
    parcel = ParcelDelivery.order(:created_at).last
    assert_equal "groceries", parcel.delivery_type
    assert_equal "Jumbo", parcel.courier_company
    assert_equal person_of(@concierge).id, parcel.received_by_person_id
  end

  test "create without a unit of the property stores nothing" do
    sign_in_as(@concierge)

    assert_no_difference "ParcelDelivery.count" do
      post concierge_parcels_path, params: { property_id: @property.id, parcel: { unit_id: @unit_q.id } }
      post concierge_parcels_path, params: { property_id: @property.id, parcel: { delivery_type: "parcel" } }
    end

    assert_response :redirect
  end

  test "create with an invalid delivery type stores nothing" do
    sign_in_as(@concierge)

    assert_no_difference "ParcelDelivery.count" do
      post concierge_parcels_path, params: {
        property_id: @property.id, parcel: { unit_id: @unit.id, delivery_type: "piano" }
      }
    end

    assert_response :redirect
  end

  # ─── withdraw ────────────────────────────────────────────────────────────────

  test "withdraw by an eligible resident" do
    sign_in_as(@concierge)
    post withdraw_concierge_parcel_path(@waiting), params: { person_id: person_of(@picker).id }

    assert_redirected_to concierge_parcels_path(property_id: @property.id)
    @waiting.reload
    assert_equal ParcelStatuses::WITHDRAWN, @waiting.status
    assert_equal person_of(@picker).id, @waiting.withdrawn_by_person_id
  end

  test "withdraw by a resident without the permission changes nothing" do
    sign_in_as(@concierge)
    post withdraw_concierge_parcel_path(@waiting), params: { person_id: person_of(@relative).id }

    assert_response :redirect
    assert_equal ParcelStatuses::RECEIVED, @waiting.reload.status
  end

  test "withdraw of another property's parcel changes nothing" do
    sign_in_as(@concierge)
    post withdraw_concierge_parcel_path(@foreign), params: { person_id: person_of(@picker).id }

    assert_response :redirect
    assert_equal ParcelStatuses::RECEIVED, @foreign.reload.status
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "Password1@" } }
  end
end
