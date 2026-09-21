# frozen_string_literal: true

require "test_helper"

# /api/v1/private/concierge — OpenSpec 2026-09-21-mobile-concierge.
class Api::V1::Private::Concierge::VisitsControllerTest < ActionDispatch::IntegrationTest
  include OperationalPolicyTestHelper
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  VISITOR_DOCUMENT = "DOC-CONCIERGE-445566"
  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    @organization = organizations(:one)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property   = create_property(@organization, "Concierge API Property P")
    @property_q = create_property(@organization, "Concierge API Property Q")
    @unit   = create_unit(@property, "CA-P-101")
    @unit_q = create_unit(@property_q, "CA-Q-201")

    @concierge = create_staff_user(
      organization: @organization, email: "ca-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE, property: @property
    )
    @resident = create_user_for_organization(
      organization: @organization, email: "ca-resident@example.test", role: AvailableRoles::CLIENT
    )
    UnitOccupancy.create!(
      organization: @organization, person: @resident.person_for(@organization), unit: @unit,
      occupancy_type: OccupancyTypes::TENANT, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_authorize_visits: true
    )

    @authorized = create_visit(@unit, "Ana Llegando", email: "ca-ana@example.test", document: VISITOR_DOCUMENT, photo: true)
    @inside     = create_visit(@unit, "Beto Adentro", status: VisitStatuses::CHECKED_IN)
    @foreign    = create_visit(@unit_q, "Carla Otra Propiedad")
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── properties ──────────────────────────────────────────────────────────────

  test "properties lists only the operated property" do
    request_as(@concierge) { get api_v1_private_concierge_properties_path, headers: JSON_HEADERS }

    assert_response :ok
    assert_equal [ @property.id.to_s ], data.map { |p| p["id"].to_s }
    assert_equal "Concierge API Property P", data.first["name"]
  end

  test "properties is empty for a resident" do
    request_as(@resident) { get api_v1_private_concierge_properties_path, headers: JSON_HEADERS }

    assert_response :ok
    assert_empty data
  end

  test "properties requires authentication" do
    host! "#{@organization.subdomain}.example.com"
    get api_v1_private_concierge_properties_path, headers: JSON_HEADERS

    assert_response :unauthorized
  end

  # ─── index ───────────────────────────────────────────────────────────────────

  test "index defaults to the authorized tab with counters and minimal visitor data" do
    list(@concierge, property_id: @property.id)

    assert_response :ok
    assert_equal [ "Ana Llegando" ], data.map { |v| v.dig("visitor", "name") }
    assert_equal({ "authorized" => 1, "checked_in" => 1, "checked_out" => 0 }, body["counters"])
    assert_equal 1, body.dig("pagination", "total_count")

    entry = data.first
    assert_includes entry.dig("unit", "display_name").to_s, "CA-P-101"
    assert_equal true, entry["can_check_in"]
    assert_equal false, entry["can_check_out"]
    assert entry.dig("visitor", "avatar_url").present?
    assert_not_includes response.body, "ca-ana@example.test"
    assert_not_includes response.body, VISITOR_DOCUMENT
  end

  test "index filters by tab" do
    list(@concierge, property_id: @property.id, tab: "checked_in")

    assert_equal [ "Beto Adentro" ], data.map { |v| v.dig("visitor", "name") }
    assert_equal true, data.first["can_check_out"]
  end

  test "index never leaks another property's visits" do
    list(@concierge, property_id: @property.id)

    assert_not_includes response.body, "Carla Otra Propiedad"
  end

  test "index searches by visitor name" do
    create_visit(@unit, "Zoe Distinta")

    list(@concierge, property_id: @property.id, q: "Zoe")

    assert_equal [ "Zoe Distinta" ], data.map { |v| v.dig("visitor", "name") }
    assert_equal 2, body.dig("counters", "authorized")
  end

  test "index is forbidden for a property outside the assignment or without property_id" do
    list(@concierge, property_id: @property_q.id)
    assert_response :forbidden

    list(@concierge, {})
    assert_response :forbidden
  end

  test "index is forbidden for a resident" do
    list(@resident, property_id: @property.id)

    assert_response :forbidden
  end

  # ─── check_in / check_out ────────────────────────────────────────────────────

  test "check_in registers the entry and ignores operational fields" do
    request_as(@concierge) do
      post check_in_api_v1_private_concierge_visit_path(@authorized),
           params: { check_in: { vehicle_plate: "ABCD12" } }, headers: JSON_HEADERS
    end

    assert_response :ok
    assert_equal VisitStatuses::CHECKED_IN, @authorized.reload.status
    assert_equal @concierge.id, @authorized.checked_in_by_id
    assert_nil @authorized.metadata.dig("check_in", "vehicle_plate")
    assert_equal false, data["can_check_in"]
    assert_equal true, data["can_check_out"]
  end

  test "check_in is 422 for a cancelled visit" do
    @authorized.update_columns(status: VisitStatuses::CANCELLED)

    request_as(@concierge) { post check_in_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }

    assert_includes [ 404, 422 ], response.status
    assert_equal VisitStatuses::CANCELLED, @authorized.reload.status
  end

  test "a visit before its validity window is listed without the check-in action" do
    @authorized.update_columns(valid_from: 2.hours.from_now, valid_until: 6.hours.from_now)

    list(@concierge, property_id: @property.id)
    assert_equal false, data.first["can_check_in"]

    request_as(@concierge) { post check_in_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }
    assert_response :unprocessable_entity
  end

  test "a visitor without photo cannot be checked in" do
    no_photo = create_visit(@unit, "Nico Sin Foto")

    list(@concierge, property_id: @property.id, q: "Nico")
    assert_nil data.first.dig("visitor", "avatar_url")
    assert_equal false, data.first["can_check_in"]

    request_as(@concierge) { post check_in_api_v1_private_concierge_visit_path(no_photo), headers: JSON_HEADERS }
    assert_response :unprocessable_entity
    assert_equal VisitStatuses::AUTHORIZED, no_photo.reload.status
  end

  # ─── deny_entry ──────────────────────────────────────────────────────────────

  test "deny_entry keeps the visit authorized, records the event and notifies only the host" do
    other_resident = create_user_for_organization(
      organization: @organization, email: "ca-other-resident@example.test", role: AvailableRoles::CLIENT
    )
    UnitOccupancy.create!(
      organization: @organization, person: other_resident.person_for(@organization), unit: @unit,
      occupancy_type: OccupancyTypes::TENANT, starts_at: 7.days.ago,
      status: OccupancyStatuses::ACTIVE, can_authorize_visits: true
    )

    assert_enqueued_with(job: DeliverPushNotificationJob) do
      request_as(@concierge) { post deny_entry_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }
    end

    assert_response :ok
    assert_equal VisitStatuses::AUTHORIZED, @authorized.reload.status

    event = @authorized.visit_status_histories.where(event_type: VisitEventTypes::ENTRY_DENIED).last
    assert_equal @concierge.id, event.actor_user_id

    denied = @authorized.notifications.where(notification_type: NotificationTypes::VISIT_ENTRY_DENIED)
    assert_equal [ @resident.person_for(@organization).id ], denied.pluck(:recipient_person_id)
  end

  test "deny_entry is 429 with Retry-After inside the cooldown" do
    request_as(@concierge) { post deny_entry_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }
    assert_response :ok

    assert_no_difference -> { Notification.count } do
      request_as(@concierge) { post deny_entry_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }
    end

    assert_response :too_many_requests
    assert_in_delta 300, response.headers["Retry-After"].to_i, 5
  end

  test "deny_entry is 422 for a visit already inside" do
    request_as(@concierge) { post deny_entry_api_v1_private_concierge_visit_path(@inside), headers: JSON_HEADERS }

    assert_response :unprocessable_entity
    assert_empty @inside.visit_status_histories.where(event_type: VisitEventTypes::ENTRY_DENIED)
  end

  test "deny_entry is out of reach for another property and for a resident" do
    request_as(@concierge) { post deny_entry_api_v1_private_concierge_visit_path(@foreign), headers: JSON_HEADERS }
    assert_response :not_found

    request_as(@resident) { post deny_entry_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }
    assert_includes [ 403, 404 ], response.status
    assert_empty @authorized.notifications.where(notification_type: NotificationTypes::VISIT_ENTRY_DENIED)
  end

  test "check_in is 404 for a visit of another property" do
    request_as(@concierge) { post check_in_api_v1_private_concierge_visit_path(@foreign), headers: JSON_HEADERS }

    assert_response :not_found
    assert_equal VisitStatuses::AUTHORIZED, @foreign.reload.status
  end

  test "resident cannot check in a visit of their own unit" do
    request_as(@resident) { post check_in_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }

    assert_includes [ 403, 404 ], response.status
    assert_equal VisitStatuses::AUTHORIZED, @authorized.reload.status
  end

  test "check_out registers the exit" do
    request_as(@concierge) do
      post check_out_api_v1_private_concierge_visit_path(@inside),
           params: { check_out: { notes: "Sin novedad" } }, headers: JSON_HEADERS
    end

    assert_response :ok
    assert_equal VisitStatuses::CHECKED_OUT, @inside.reload.status
    assert_equal false, data["can_check_out"]
  end

  test "check_out is 422 for a visit that has not entered" do
    request_as(@concierge) { post check_out_api_v1_private_concierge_visit_path(@authorized), headers: JSON_HEADERS }

    assert_response :unprocessable_entity
    assert_equal VisitStatuses::AUTHORIZED, @authorized.reload.status
  end

  private

  def body
    JSON.parse(response.body)
  end

  def data
    body.fetch("data")
  end

  def list(user, params)
    request_as(user) { get api_v1_private_concierge_visits_path, params: params, headers: JSON_HEADERS }
  end

  def request_as(user)
    host! "#{@organization.subdomain}.example.com"
    sign_in user
    yield
    sign_out user
  end

  # photo: true gives the visitor an account with a profile photo — the only
  # kind of visitor the mobile concierge can check in.
  def create_visit(unit, name, status: VisitStatuses::AUTHORIZED, email: nil, document: nil, photo: false)
    person =
      if photo
        user = create_user_for_organization(organization: @organization, email: email, role: AvailableRoles::VISITOR)
        user.avatar.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
        user.person_for(@organization).tap { |linked| linked.update!(display_name: name) }
      else
        Person.new(
          organization: @organization, display_name: name,
          person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
        )
      end
    person.contact_email = email if email
    person.document_number = document if document
    person.save!

    visit = Visit.create!(
      organization: @organization, unit: unit, visitor_person: person,
      scheduled_at: 10.minutes.ago, status: VisitStatuses::AUTHORIZED,
      visit_type: VisitTypes::GUEST, created_by: @resident, authorized_by: @resident
    )
    visit.update_columns(status: status, checked_in_at: Time.zone.now) if status == VisitStatuses::CHECKED_IN
    visit
  end
end
