# frozen_string_literal: true

require "test_helper"

# POST /api/v1/private/units/:unit_id/visits/:id/authorize and /reject —
# OpenSpec 2026-09-21-mobile-visit-authorization.
class Api::V1::Private::Units::VisitsAuthorizationControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property   = create_property(@organization, "Visit Authorization Property")
    @unit       = create_unit(@property, "VA-101")
    @other_unit = create_unit(@property, "VA-102")

    @resident = create_user_for_organization(
      organization: @organization, email: "va-resident@example.test", role: AvailableRoles::CLIENT
    )
    create_occupancy(@resident, @unit, can_authorize_visits: true)

    @no_auth_resident = create_user_for_organization(
      organization: @organization, email: "va-no-auth@example.test", role: AvailableRoles::CLIENT
    )
    create_occupancy(@no_auth_resident, @unit, can_authorize_visits: false)

    @visit = create_pending_visit("Pending Visitor", email: "va-visitor@example.test")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "show exposes the answer flags while pending" do
    request_as(@resident) { get api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_equal true, data["can_authorize"]
    assert_equal true, data["can_reject"]
  end

  test "authorize moves the visit to authorized and notifies the visitor" do
    assert_enqueued_emails 1 do
      request_as(@resident) { post authorize_path(@unit, @visit) }
    end

    assert_response :ok
    assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
    assert_equal @resident.id, @visit.authorized_by_id
    assert_equal false, data["can_authorize"]
    assert_equal false, data["can_reject"]
    assert_equal true, data["can_cancel"]
  end

  test "authorize sends nothing when the visitor has no contact data" do
    visit = create_pending_visit("No Contact Visitor")

    assert_no_enqueued_emails do
      request_as(@resident) { post authorize_path(@unit, visit) }
    end

    assert_response :ok
    assert_equal VisitStatuses::AUTHORIZED, visit.reload.status
  end

  test "reject moves the visit to rejected without notifying the visitor" do
    assert_no_enqueued_emails do
      request_as(@resident) { post reject_path(@unit, @visit) }
    end

    assert_response :ok
    assert_equal VisitStatuses::REJECTED, @visit.reload.status
    assert_equal false, data["can_cancel"]
  end

  test "an already answered visit is 422 for both actions" do
    @visit.update_columns(status: VisitStatuses::AUTHORIZED)

    request_as(@resident) { post authorize_path(@unit, @visit) }
    assert_response :unprocessable_entity

    request_as(@resident) { post reject_path(@unit, @visit) }
    assert_response :unprocessable_entity
    assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
  end

  test "both actions are forbidden without authorize_visits" do
    request_as(@no_auth_resident) { post authorize_path(@unit, @visit) }
    assert_response :forbidden

    request_as(@no_auth_resident) { post reject_path(@unit, @visit) }
    assert_response :forbidden
    assert_equal VisitStatuses::PENDING, @visit.reload.status
  end

  test "both actions are 404 for a visit of another unit" do
    create_occupancy(@resident, @other_unit, can_authorize_visits: true)

    request_as(@resident) { post authorize_path(@other_unit, @visit) }
    assert_response :not_found

    request_as(@resident) { post reject_path(@other_unit, @visit) }
    assert_response :not_found
    assert_equal VisitStatuses::PENDING, @visit.reload.status
  end

  private

  def data
    JSON.parse(response.body).fetch("data")
  end

  def authorize_path(unit, visit)
    authorize_api_v1_private_unit_visit_path(unit_id: unit.id, id: visit.id)
  end

  def reject_path(unit, visit)
    reject_api_v1_private_unit_visit_path(unit_id: unit.id, id: visit.id)
  end

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end

  def create_occupancy(user, unit, can_authorize_visits:)
    UnitOccupancy.create!(
      organization: @organization, person: user.person_for(@organization), unit: unit,
      occupancy_type: OccupancyTypes::TENANT, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_authorize_visits: can_authorize_visits
    )
  end

  def create_pending_visit(name, email: nil)
    person = Person.new(
      organization: @organization, display_name: name,
      person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
    )
    person.contact_email = email if email
    person.save!

    Visit.create!(
      organization: @organization, unit: @unit, visitor_person: person,
      scheduled_at: 1.day.from_now, status: VisitStatuses::PENDING, visit_type: VisitTypes::GUEST
    )
  end
end
