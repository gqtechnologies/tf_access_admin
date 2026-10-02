# frozen_string_literal: true

require "test_helper"

# GET /api/v1/private/units/:unit_id/residents — mobile-private-api "Unit residents endpoint".
class Api::V1::Private::Units::ResidentsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = organizations(:one)
    @other_org    = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Residents API Property")
    @unit     = create_unit(@property, "RS-101")

    @tenant = member("residents-tenant@example.test", "Zoe Tenant")
    occupy(@tenant, OccupancyTypes::TENANT, can_authorize_visits: true)

    @owner = member("residents-owner@example.test", "Ana Owner")
    own(@owner)

    @relative = member("residents-relative@example.test", "Beto Relative")
    occupy(@relative, OccupancyTypes::FAMILY_MEMBER)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "lists everyone with an active relationship, the requester first then by name" do
    get_residents(@tenant)

    assert_response :ok
    data = response.parsed_body.fetch("data")

    assert_equal [ "Zoe Tenant", "Ana Owner", "Beto Relative" ], data.map { |r| r["name"] }
    assert_equal [ true, false, false ], data.map { |r| r["is_me"] }
    assert_equal [ [ "tenant" ], [ "owner" ], [ "family_member" ] ], data.map { |r| r["relationships"] }
    assert_equal [ true, false, false ], data.map { |r| r["can_authorize_visits"] }
    assert_equal person_of(@tenant).id, data.first["id"]
  end

  test "exposes no contact data" do
    get_residents(@tenant)

    assert_equal %w[avatar_url can_authorize_visits id is_me name relationships],
      response.parsed_body.fetch("data").first.keys.sort
  end

  test "a person who owns and occupies appears once with both relationships" do
    occupy(@owner, OccupancyTypes::OWNER_RESIDENT, can_authorize_visits: true)

    get_residents(@owner)

    data = response.parsed_body.fetch("data")
    assert_equal 3, data.size
    assert_equal %w[owner owner_resident], data.first["relationships"]
    assert data.first["can_authorize_visits"]
  end

  test "ended, future and inactive relationships are left out" do
    ended = member("residents-ended@example.test", "Ended Person")
    UnitOccupancy.create!(
      organization: @organization, person: person_of(ended), unit: @unit,
      occupancy_type: OccupancyTypes::TENANT, starts_at: 30.days.ago, ends_at: 2.days.ago,
      status: OccupancyStatuses::ACTIVE
    )
    future = member("residents-future@example.test", "Future Person")
    UnitOwnership.create!(
      organization: @organization, person: person_of(future), unit: @unit,
      ownership_percentage: 10, starts_at: 5.days.from_now.to_date, status: UnitOwnership::STATUS_ACTIVE
    )
    UnitOccupancy.where(person: person_of(@relative)).update_all(status: "ended")

    get_residents(@tenant)

    assert_equal [ "Zoe Tenant", "Ana Owner" ], response.parsed_body.fetch("data").map { |r| r["name"] }
  end

  test "member without a relationship with the unit is forbidden" do
    stranger = member("residents-stranger@example.test", "Stranger")

    get_residents(stranger)

    assert_response :forbidden
  end

  test "unit of another organization is not found" do
    foreign_unit = ActsAsTenant.with_tenant(@other_org) do
      create_unit(create_property(@other_org, "Foreign Property"), "FX-1")
    end

    get_residents(@tenant, unit: foreign_unit)

    assert_response :not_found
  end

  test "requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_unit_residents_path(@unit), headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  private

  def member(email, name)
    create_user_for_organization(organization: @organization, email: email, role: AvailableRoles::CLIENT, name: name)
  end

  def person_of(user)
    user.person_for(@organization)
  end

  def occupy(user, type, can_authorize_visits: false)
    UnitOccupancy.create!(
      organization: @organization, person: person_of(user), unit: @unit,
      occupancy_type: type, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_authorize_visits: can_authorize_visits
    )
  end

  def own(user)
    UnitOwnership.create!(
      organization: @organization, person: person_of(user), unit: @unit,
      ownership_percentage: 50, starts_at: Date.current, status: UnitOwnership::STATUS_ACTIVE
    )
  end

  def get_residents(user, unit: @unit)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    get api_v1_private_unit_residents_path(unit), headers: { "Accept" => "application/json" }
    sign_out user
  end
end
