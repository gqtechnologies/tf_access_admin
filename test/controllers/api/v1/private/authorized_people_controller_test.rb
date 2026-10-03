# frozen_string_literal: true

require "test_helper"

# /api/v1/private/units/:unit_id/authorized_people and /concierge/authorized_people —
# OpenSpec 2026-10-02-authorized-residents.
class Api::V1::Private::AuthorizedPeopleControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    setup_reservation_world("AP2")
    UnitOccupancy.where(person: person_of(@picker)).update_all(can_authorize_visits: true)
    ActsAsTenant.current_tenant = nil
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "a resident proposes and lists; another resident sees it but cannot propose" do
    request_as(@picker) do
      post api_v1_private_unit_authorized_people_path(@unit), headers: JSON_HEADERS, params: {
        person: { name: "Nora Nana", email: "nora@example.test", document: "22.333.444-5" },
        authorization: { relationship_type: "staff", can_withdraw_parcels: true, ends_at: 30.days.from_now.to_date.iso8601 }
      }
    end

    assert_response :created
    assert_equal "pending", response.parsed_body.dig("data", "status")
    assert_equal "Nora Nana", response.parsed_body.dig("data", "name")

    request_as(@relative) { get api_v1_private_unit_authorized_people_path(@unit), headers: JSON_HEADERS }
    assert_equal [ "Nora Nana" ], response.parsed_body["data"].map { |p| p["name"] }
    assert_equal false, response.parsed_body["can_propose"]
    assert_includes response.parsed_body["relationship_types"], "staff"

    request_as(@relative) do
      post api_v1_private_unit_authorized_people_path(@unit), headers: JSON_HEADERS, params: {
        person: { name: "X", email: "x@example.test" }
      }
    end
    assert_response :forbidden
  end

  test "withdrawing takes the person off the list" do
    record = ActsAsTenant.with_tenant(@organization) do
      AuthorizedResidents::Propose.call(unit: @unit, proposer: person_of(@picker),
                                        person_params: { name: "Nora", email: "nora2@example.test", document: "5-1" })
    end
    ActsAsTenant.current_tenant = nil

    request_as(@owner) { post withdraw_api_v1_private_unit_authorized_person_path(@unit, record), headers: JSON_HEADERS }
    assert_response :ok
    assert_equal "revoked", response.parsed_body.dig("data", "status")

    request_as(@owner) { get api_v1_private_unit_authorized_people_path(@unit), headers: JSON_HEADERS }
    assert_empty response.parsed_body["data"]
  end

  test "the front desk lists approved, valid people of the property and searches by name or document" do
    approved, pending = ActsAsTenant.with_tenant(@organization) do
      a = AuthorizedResidents::Propose.call(unit: @unit, proposer: person_of(@picker),
                                            person_params: { name: "Nora Nana", email: "n3@example.test", document: "22.333.444-5" })
      AuthorizedResidents::Decide.call(authorized_resident: a, actor: @tenant_admin, decision: :approve)
      p = AuthorizedResidents::Propose.call(unit: @unit, proposer: person_of(@picker),
                                            person_params: { name: "Pedro Pendiente", email: "p3@example.test", document: "7-7" })
      [ a, p ]
    end
    ActsAsTenant.current_tenant = nil

    request_as(@concierge) do
      get api_v1_private_concierge_authorized_people_path, params: { property_id: @property.id }, headers: JSON_HEADERS
    end
    assert_response :ok
    assert_equal [ approved.id ], response.parsed_body["data"].map { |p| p["id"] }
    assert_equal "22.333.444-5", response.parsed_body["data"].first["document"]
    assert_not_includes response.parsed_body["data"].map { |p| p["id"] }, pending.id

    { "nora" => 1, "22.333.444-5" => 1, "nadie" => 0 }.each do |q, expected|
      request_as(@concierge) do
        get api_v1_private_concierge_authorized_people_path, params: { property_id: @property.id, q: q }, headers: JSON_HEADERS
      end
      assert_equal expected, response.parsed_body["data"].size, q
    end

    request_as(@picker) do
      get api_v1_private_concierge_authorized_people_path, params: { property_id: @property.id }, headers: JSON_HEADERS
    end
    assert_response :forbidden
  end

  private

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end
end
