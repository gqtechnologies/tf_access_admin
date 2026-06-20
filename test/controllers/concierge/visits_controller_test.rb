# frozen_string_literal: true

require "test_helper"

class Concierge::VisitsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Concierge Ctrl Property P")
    @other_property = create_property(@organization, "Concierge Ctrl Property Q")
    @unit = create_unit(@property, "CC-P-101")

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "conc-ctrl-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @concierge = create_staff_user(
      organization: @organization,
      email: "conc-ctrl-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE,
      property: @property
    )
    @concierge_q = create_staff_user(
      organization: @organization,
      email: "conc-ctrl-concierge-q@example.test",
      staff_type: StaffTypes::CONCIERGE,
      property: @other_property
    )
    @owner = create_owner_user(
      organization: @organization,
      email: "conc-ctrl-owner@example.test",
      unit: @unit
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "conc-ctrl-client@example.test",
      role: AvailableRoles::CLIENT
    )

    host_person = @owner.person_for(@organization)
    visitor = Person.create!(
      organization: @organization,
      display_name: "Concierge Ctrl Visitor",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    @authorized_visit = ActsAsTenant.with_tenant(@organization) do
      Visit.create!(
        organization: @organization,
        unit: @unit,
        visitor_person: visitor,
        host_person: host_person,
        scheduled_at: 1.hour.from_now,
        valid_from: 30.minutes.ago,
        status: VisitStatuses::AUTHORIZED,
        authorized_at: 10.minutes.ago,
        authorized_by_id: @tenant_admin.id
      )
    end

    @pending_visit = ActsAsTenant.with_tenant(@organization) do
      visitor2 = Person.create!(
        organization: @organization,
        display_name: "Concierge Ctrl Visitor 2",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      Visit.create!(
        organization: @organization,
        unit: @unit,
        visitor_person: visitor2,
        host_person: host_person,
        scheduled_at: 2.days.from_now,
        valid_from: 2.days.from_now,
        status: VisitStatuses::PENDING
      )
    end
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── index ───────────────────────────────────────────────────────────────────

  test "concierge can access operational visits list" do
    sign_in_as(@concierge)
    inertia_get concierge_visits_path
    assert_response :success
    assert_equal "concierge/visits/index", inertia_component
  end

  test "client without concierge role is redirected from operational list" do
    sign_in_as(@client)
    get concierge_visits_path
    assert_response :redirect
  end

  # ─── show ────────────────────────────────────────────────────────────────────

  test "concierge can show an authorized visit on their property" do
    sign_in_as(@concierge)
    inertia_get concierge_visit_path(@authorized_visit)
    assert_response :success
    assert_equal "concierge/visits/show", inertia_component
  end

  test "pending visit is outside concierge scope (6.4, §5.5)" do
    sign_in_as(@concierge)
    get concierge_visit_path(@pending_visit)
    assert_response :redirect
  end

  test "concierge_q cannot show visit on property P (cross-property, 6.8)" do
    sign_in_as(@concierge_q)
    get concierge_visit_path(@authorized_visit)
    assert_response :redirect
  end

  # ─── check_in ────────────────────────────────────────────────────────────────

  test "concierge can check in an authorized visit" do
    sign_in_as(@concierge)
    post check_in_concierge_visit_path(@authorized_visit), params: {
      check_in: { access_point: "main_entrance" }
    }
    assert_response :redirect
    assert_equal VisitStatuses::CHECKED_IN, @authorized_visit.reload.status
  end

  test "concierge_q cannot check in visit on property P (cross-property, 6.8)" do
    sign_in_as(@concierge_q)
    post check_in_concierge_visit_path(@authorized_visit), params: {
      check_in: {}
    }
    assert_response :redirect
    assert_equal VisitStatuses::AUTHORIZED, @authorized_visit.reload.status
  end

  # ─── check_out ───────────────────────────────────────────────────────────────

  test "concierge can check out a checked_in visit" do
    @authorized_visit.update_columns(
      status: VisitStatuses::CHECKED_IN,
      checked_in_at: 1.hour.ago,
      checked_in_by_id: @tenant_admin.id
    )
    sign_in_as(@concierge)
    post check_out_concierge_visit_path(@authorized_visit), params: {
      check_out: { notes: "Normal exit" }
    }
    assert_response :redirect
    assert_equal VisitStatuses::CHECKED_OUT, @authorized_visit.reload.status
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
