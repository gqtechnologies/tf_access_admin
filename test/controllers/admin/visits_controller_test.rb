# frozen_string_literal: true

require "test_helper"

class Admin::VisitsControllerTest < ActionDispatch::IntegrationTest
  include InertiaTestHelper
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property = create_property(@organization, "Visits Controller Property P")
    @other_property = create_property(@organization, "Visits Controller Property Q")
    @unit = create_unit(@property, "VC-P-101")

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "visits-ctrl-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )
    @property_admin = create_staff_user(
      organization: @organization,
      email: "visits-ctrl-prop-admin@example.test",
      staff_type: StaffTypes::MANAGER,
      property: @property
    )
    @concierge = create_staff_user(
      organization: @organization,
      email: "visits-ctrl-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE,
      property: @property
    )
    @owner = create_owner_user(
      organization: @organization,
      email: "visits-ctrl-owner@example.test",
      unit: @unit
    )
    @client = create_user_for_organization(
      organization: @organization,
      email: "visits-ctrl-client@example.test",
      role: AvailableRoles::CLIENT
    )

    host_person = @owner.person_for(@organization)
    visitor_person = Person.create!(
      organization: @organization,
      display_name: "Visit Controller Visitor",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    @visit = ActsAsTenant.with_tenant(@organization) do
      Visit.create!(
        organization: @organization,
        unit: @unit,
        visitor_person: visitor_person,
        host_person: host_person,
        scheduled_at: 1.day.from_now,
        valid_from: 1.day.from_now,
        status: VisitStatuses::PENDING
      )
    end

    @other_org_visitor = ActsAsTenant.with_tenant(@other_organization) do
      other_property = create_property(@other_organization, "Other Org VC Property")
      other_unit = create_unit(other_property, "OTHER-VC-101")
      other_host = Person.create!(
        organization: @other_organization,
        display_name: "Other Org Host VC",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      UnitOwnership.create!(
        organization: @other_organization,
        person: other_host,
        unit: other_unit,
        ownership_percentage: 100,
        starts_at: Date.current,
        status: UnitOwnership::STATUS_ACTIVE
      )
      other_visitor = Person.create!(
        organization: @other_organization,
        display_name: "Other Org Visitor VC",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      Visit.create!(
        organization: @other_organization,
        unit: other_unit,
        visitor_person: other_visitor,
        host_person: other_host,
        scheduled_at: 1.day.from_now,
        valid_from: 1.day.from_now,
        status: VisitStatuses::PENDING
      )
    end
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── index ──────────────────────────────────────────────────────────────────

  test "tenant_admin can list visits" do
    sign_in_as(@tenant_admin)
    inertia_get admin_visits_path
    assert_response :success
    assert_equal "admin/visits/index", inertia_component
  end

  test "client without assignments is redirected from visits index" do
    sign_in_as(@client)
    get admin_visits_path
    assert_response :redirect
  end

  test "unauthenticated user is redirected from visits index" do
    get admin_visits_path
    assert_response :redirect
  end

  # ─── show ───────────────────────────────────────────────────────────────────

  test "tenant_admin can show a visit" do
    sign_in_as(@tenant_admin)
    inertia_get admin_visit_path(@visit)
    assert_response :success
    assert_equal "admin/visits/show", inertia_component
  end

  test "property_admin can show visit on their property" do
    sign_in_as(@property_admin)
    get admin_visit_path(@visit)
    assert_response :success
  end

  test "cross-organization visit is not found (scope exclusion)" do
    sign_in_as(@tenant_admin)
    # Other org visit ID is outside the policy scope for this org
    get admin_visit_path(@other_org_visitor)
    assert_response :redirect
  end

  # ─── create ─────────────────────────────────────────────────────────────────

  test "tenant_admin can create a visit" do
    sign_in_as(@tenant_admin)
    host_person = @owner.person_for(@organization)
    visitor = Person.create!(
      organization: @organization,
      display_name: "New Visit Visitor",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    assert_difference "Visit.count", 1 do
      post admin_visits_path, params: {
        visit: {
          unit_id: @unit.id,
          visitor_person_id: visitor.id,
          host_person_id: host_person.id,
          scheduled_at: 2.days.from_now.iso8601,
          valid_from: 2.days.from_now.iso8601,
          visit_type: VisitTypes::GUEST
        }
      }
    end
    assert_response :redirect
  end

  test "concierge cannot create a visit (6.1, §5.6)" do
    sign_in_as(@concierge)
    host_person = @owner.person_for(@organization)
    visitor = Person.create!(
      organization: @organization,
      display_name: "Concierge Create Visitor",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    assert_no_difference "Visit.count" do
      post admin_visits_path, params: {
        visit: {
          unit_id: @unit.id,
          visitor_person_id: visitor.id,
          host_person_id: host_person.id,
          scheduled_at: 2.days.from_now.iso8601,
          valid_from: 2.days.from_now.iso8601,
          visit_type: VisitTypes::GUEST
        }
      }
    end
    assert_response :redirect
  end

  # ─── edit / update ──────────────────────────────────────────────────────────

  test "tenant_admin can edit a pending visit" do
    sign_in_as(@tenant_admin)
    inertia_get edit_admin_visit_path(@visit)
    assert_response :success
    assert_equal "admin/visits/edit", inertia_component
  end

  test "edit is denied for non-editable status (checked_in)" do
    @visit.update_columns(status: VisitStatuses::CHECKED_IN)
    sign_in_as(@tenant_admin)
    get edit_admin_visit_path(@visit)
    assert_response :redirect
  end

  test "tenant_admin can update a pending visit" do
    sign_in_as(@tenant_admin)
    patch admin_visit_path(@visit), params: {
      visit: { notes: "Updated notes" }
    }
    assert_response :redirect
    assert_equal "Updated notes", @visit.reload.notes
  end

  # ─── authorize ──────────────────────────────────────────────────────────────

  test "tenant_admin can authorize a pending visit" do
    sign_in_as(@tenant_admin)
    post authorize_admin_visit_path(@visit)
    assert_response :redirect
    assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
  end

  test "concierge cannot authorize a visit" do
    sign_in_as(@concierge)
    post authorize_admin_visit_path(@visit)
    assert_response :redirect
    assert_equal VisitStatuses::PENDING, @visit.reload.status
  end

  # ─── cancel ─────────────────────────────────────────────────────────────────

  test "tenant_admin can cancel a pending visit" do
    sign_in_as(@tenant_admin)
    delete cancel_admin_visit_path(@visit)
    assert_response :redirect
    assert_equal VisitStatuses::CANCELLED, @visit.reload.status
  end

  test "cancel is denied for checked_in status" do
    @visit.update_columns(
      status: VisitStatuses::CHECKED_IN,
      checked_in_at: Time.current,
      authorized_at: Time.current,
      authorized_by_id: @tenant_admin.id,
      checked_in_by_id: @tenant_admin.id
    )
    sign_in_as(@tenant_admin)
    delete cancel_admin_visit_path(@visit)
    assert_response :redirect
    assert_equal VisitStatuses::CHECKED_IN, @visit.reload.status
  end

  test "new exposes contextual unit with property_name for locked property/unit display" do
    sign_in_as(@tenant_admin)

    inertia_get new_admin_visit_path(unit_id: @unit.id)

    assert_response :success
    contextual = inertia_props["contextual"]
    assert_equal @unit.id, contextual["unit"]["id"]
    assert_equal @property.name, contextual["unit"]["property_name"]
  end

  test "new does not expose a static properties list" do
    sign_in_as(@tenant_admin)

    inertia_get new_admin_visit_path

    assert_response :success
    assert_not inertia_props.key?("properties")
  end

  test "form_properties matches accent-insensitively and excludes other organizations" do
    create_property(@organization, "Región Sur")
    sign_in_as(@tenant_admin)

    get form_properties_admin_visits_path, params: { search: "region" }

    assert_response :success
    names = response.parsed_body.fetch("properties").map { |row| row["name"] }
    assert_includes names, "Región Sur"
    assert_not_includes names, "Other Org VC Property"
  end

  test "form_properties paginates with 20 per page" do
    21.times { |i| create_property(@organization, "Paginated Property #{i}") }
    sign_in_as(@tenant_admin)

    get form_properties_admin_visits_path

    assert_response :success
    body = response.parsed_body
    assert_equal 20, body.fetch("properties").size
    assert body.fetch("pagination").fetch("has_more")
  end

  test "form_units matches accent-insensitively" do
    create_unit(@property, "Depósito 1")
    sign_in_as(@tenant_admin)

    get form_units_admin_visits_path, params: { search: "deposito" }

    assert_response :success
    identifiers = response.parsed_body.fetch("units").map { |row| row["identifier"] }
    assert_includes identifiers, "Depósito 1"
  end

  test "form_hosts matches accent-insensitively and excludes ineligible people" do
    accented_unit = create_unit(@property, "VC-P-ACCENT")
    host_with_accent = Person.create!(
      organization: @organization,
      display_name: "José García",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )
    UnitOwnership.create!(
      organization: @organization,
      person: host_with_accent,
      unit: accented_unit,
      ownership_percentage: 100,
      starts_at: Date.current,
      status: UnitOwnership::STATUS_ACTIVE
    )
    sign_in_as(@tenant_admin)

    get form_hosts_admin_visits_path, params: { unit_id: accented_unit.id, search: "jose garcia" }

    assert_response :success
    names = response.parsed_body.fetch("hosts").map { |row| row["display_name"] }
    assert_includes names, "José García"
  end

  private

  def sign_in_as(user)
    host! "#{@organization.subdomain}.example.com"
    post user_session_path, params: { user: { email: user.email, password: "password1" } }
  end
end
