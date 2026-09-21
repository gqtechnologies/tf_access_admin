# frozen_string_literal: true

require "test_helper"

# GET/DELETE /api/v1/private/units/:unit_id/visits/:id and
# POST .../resend_invitation — OpenSpec 2026-09-21-mobile-visit-management.
class Api::V1::Private::Units::VisitsMemberControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  VISITOR_DOCUMENT = "DOC-MEMBER-778899"

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property   = create_property(@organization, "Visit Member Property")
    @unit       = create_unit(@property, "VM-101")
    @other_unit = create_unit(@property, "VM-102")

    @resident = create_user_for_organization(
      organization: @organization,
      email: "vm-resident@example.test",
      role: AvailableRoles::CLIENT
    )
    create_occupancy(@resident, @unit, can_authorize_visits: true)

    @no_auth_resident = create_user_for_organization(
      organization: @organization,
      email: "vm-no-auth@example.test",
      role: AvailableRoles::CLIENT
    )
    create_occupancy(@no_auth_resident, @unit, can_authorize_visits: false)

    @visitor = Person.new(
      organization: @organization,
      display_name: "Member Visitor",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    @visitor.contact_email = "vm-visitor@example.test"
    @visitor.contact_phone = "+56911112222"
    @visitor.document_number = VISITOR_DOCUMENT
    @visitor.save!

    @visit = create_visit(@unit)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── show ────────────────────────────────────────────────────────────────────

  test "show returns the detail with flags and without the document" do
    request_as(@resident) { get api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :ok
    data = JSON.parse(response.body).fetch("data")
    assert_equal @visit.id.to_s, data["id"].to_s
    assert_equal VisitStatuses::AUTHORIZED, data["status"]
    assert_equal "Member Visitor", data.dig("visitor", "name")
    assert_equal "vm-visitor@example.test", data.dig("visitor", "email")
    assert_equal "+56911112222", data.dig("visitor", "phone")
    assert_equal true, data["can_cancel"]
    assert_equal true, data["can_resend"]
    assert_not_includes response.body, VISITOR_DOCUMENT
  end

  test "show flags are false for a checked-in visit" do
    @visit.update_columns(status: VisitStatuses::CHECKED_IN, checked_in_at: Time.zone.now)

    request_as(@resident) { get api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    data = JSON.parse(response.body).fetch("data")
    assert_equal false, data["can_cancel"]
    assert_equal false, data["can_resend"]
  end

  test "show requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id), headers: { "Accept" => "application/json" }

    assert_response :unauthorized
  end

  test "show is forbidden without authorize_visits" do
    request_as(@no_auth_resident) { get api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :forbidden
  end

  test "show is 404 for a visit of another unit" do
    create_occupancy(@resident, @other_unit, can_authorize_visits: true)

    request_as(@resident) { get api_v1_private_unit_visit_path(unit_id: @other_unit.id, id: @visit.id) }

    assert_response :not_found
  end

  test "show is 404 for a unit of another tenant" do
    other_org = organizations(:two)
    foreign_unit = ActsAsTenant.with_tenant(other_org) do
      create_unit(create_property(other_org, "Foreign VM Property"), "VM-F-1")
    end

    request_as(@resident) { get api_v1_private_unit_visit_path(unit_id: foreign_unit.id, id: @visit.id) }

    assert_response :not_found
  end

  # ─── destroy ─────────────────────────────────────────────────────────────────

  test "destroy cancels an authorized visit and records the event" do
    request_as(@resident) { delete api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :ok
    assert_equal VisitStatuses::CANCELLED, JSON.parse(response.body).dig("data", "status")
    assert_equal VisitStatuses::CANCELLED, @visit.reload.status

    event = @visit.visit_status_histories.where(event_type: VisitEventTypes::CANCELLED).last
    assert_equal @resident.id, event.actor_user_id
  end

  test "destroy cancels a pending visit" do
    @visit.update_columns(status: VisitStatuses::PENDING)

    request_as(@resident) { delete api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :ok
    assert_equal VisitStatuses::CANCELLED, @visit.reload.status
  end

  test "destroy is 422 when the visit is no longer cancellable" do
    @visit.update_columns(status: VisitStatuses::CHECKED_IN, checked_in_at: Time.zone.now)

    request_as(@resident) { delete api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :unprocessable_entity
    assert_equal VisitStatuses::CHECKED_IN, @visit.reload.status
  end

  test "destroy is forbidden without authorize_visits" do
    request_as(@no_auth_resident) { delete api_v1_private_unit_visit_path(unit_id: @unit.id, id: @visit.id) }

    assert_response :forbidden
    assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
  end

  test "destroy is 404 for a visit of another unit" do
    create_occupancy(@resident, @other_unit, can_authorize_visits: true)

    request_as(@resident) { delete api_v1_private_unit_visit_path(unit_id: @other_unit.id, id: @visit.id) }

    assert_response :not_found
    assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
  end

  # ─── resend_invitation ───────────────────────────────────────────────────────

  test "resend_invitation notifies the visitor and turns can_resend off" do
    assert_enqueued_emails 1 do
      request_as(@resident) { post resend_path(@unit, @visit) }
    end

    assert_response :ok
    assert_equal false, JSON.parse(response.body).dig("data", "can_resend")
    assert @visit.reload.metadata[Visits::ResendVisitorInvitation::METADATA_KEY].present?
  end

  test "resend_invitation is 422 for a cancelled visit" do
    @visit.update_columns(status: VisitStatuses::CANCELLED)

    assert_no_enqueued_emails do
      request_as(@resident) { post resend_path(@unit, @visit) }
    end

    assert_response :unprocessable_entity
  end

  test "resend_invitation is 422 for an expired authorization" do
    @visit.update_columns(valid_from: 3.hours.ago, valid_until: 1.hour.ago)

    assert_no_enqueued_emails do
      request_as(@resident) { post resend_path(@unit, @visit) }
    end

    assert_response :unprocessable_entity
  end

  test "resend_invitation is 429 with Retry-After inside the cooldown" do
    @visit.update_column(
      :metadata,
      { Visits::ResendVisitorInvitation::METADATA_KEY => 2.minutes.ago.iso8601 }
    )

    assert_no_enqueued_emails do
      request_as(@resident) { post resend_path(@unit, @visit) }
    end

    assert_response :too_many_requests
    assert_in_delta 180, response.headers["Retry-After"].to_i, 5
  end

  test "resend_invitation is 404 for a visit of another unit" do
    create_occupancy(@resident, @other_unit, can_authorize_visits: true)

    request_as(@resident) { post resend_path(@other_unit, @visit) }

    assert_response :not_found
  end

  private

  def resend_path(unit, visit)
    resend_invitation_api_v1_private_unit_visit_path(unit_id: unit.id, id: visit.id)
  end

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end

  def create_occupancy(user, unit, can_authorize_visits:)
    UnitOccupancy.create!(
      organization: @organization,
      person: user.person_for(@organization),
      unit: unit,
      occupancy_type: OccupancyTypes::TENANT,
      starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE,
      can_authorize_visits: can_authorize_visits
    )
  end

  def create_visit(unit)
    Visit.create!(
      organization: @organization,
      unit: unit,
      visitor_person: @visitor,
      scheduled_at: 1.day.from_now,
      status: VisitStatuses::AUTHORIZED,
      visit_type: VisitTypes::GUEST,
      created_by: @resident,
      authorized_by: @resident
    )
  end
end
