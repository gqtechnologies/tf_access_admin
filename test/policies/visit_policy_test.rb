# frozen_string_literal: true

require "test_helper"

# Tests for VisitPolicy authorization contract (OpenSpec 4.1–4.3).
#
# Validates that each action uses the correct capability and scope without
# granting cross-organization or cross-property access.
class VisitPolicyTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper

  setup do
    @organization = organizations(:one)
    @other_organization = organizations(:two)
    ActsAsTenant.current_tenant = @organization
    Current.reset

    @property_p = create_property(@organization, "Visit Policy Property P")
    @property_q = create_property(@organization, "Visit Policy Property Q")
    @unit_p = create_unit(@property_p, "VP-P-101")
    @unit_q = create_unit(@property_q, "VP-Q-101")

    @tenant_admin = create_user_for_organization(
      organization: @organization,
      email: "visit-policy-tenant-admin@example.test",
      role: AvailableRoles::TENANT_ADMIN
    )

    @property_admin_p = create_staff_user(
      organization: @organization,
      email: "visit-policy-property-admin@example.test",
      staff_type: StaffTypes::MANAGER,
      property: @property_p
    )

    @concierge_p = create_staff_user(
      organization: @organization,
      email: "visit-policy-concierge@example.test",
      staff_type: StaffTypes::CONCIERGE,
      property: @property_p
    )

    @owner = create_owner_user(
      organization: @organization,
      email: "visit-policy-owner@example.test",
      unit: @unit_p
    )

    @resident = create_resident_user(
      organization: @organization,
      email: "visit-policy-resident@example.test",
      unit: @unit_p
    )

    @client = create_user_for_organization(
      organization: @organization,
      email: "visit-policy-client@example.test",
      role: AvailableRoles::CLIENT
    )

    person_p = Person.create!(
      organization: @organization,
      display_name: "Visit Visitor P",
      person_type: PersonTypes::NATURAL,
      status: PersonStatuses::ACTIVE
    )

    @visit_p = Visit.create!(
      organization: @organization,
      residential_property: @property_p,
      unit: @unit_p,
      scheduled_starts_at: 1.day.from_now,
      responsible_person: person_p,
      status: "pending"
    )

    @visit_q = ActsAsTenant.with_tenant(@organization) do
      person_q = Person.create!(
        organization: @organization,
        display_name: "Visit Visitor Q",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      Visit.create!(
        organization: @organization,
        residential_property: @property_q,
        unit: @unit_q,
        scheduled_starts_at: 1.day.from_now,
        responsible_person: person_q,
        status: "pending"
      )
    end

    @other_org_visit = ActsAsTenant.with_tenant(@other_organization) do
      other_property = create_property(@other_organization, "Other Org Visit Property")
      other_unit = create_unit(other_property, "OTHER-VP-101")
      other_person = Person.create!(
        organization: @other_organization,
        display_name: "Other Org Visitor",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      Visit.create!(
        organization: @other_organization,
        residential_property: other_property,
        unit: other_unit,
        scheduled_starts_at: 1.day.from_now,
        responsible_person: other_person,
        status: "pending"
      )
    end
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  # ─── tenant_admin (organization-wide) ───────────────────────────────────────

  test "tenant_admin can index and show visits organization-wide" do
    assert VisitPolicy.new(@tenant_admin, @visit_p).index?
    assert VisitPolicy.new(@tenant_admin, @visit_p).show?
    assert VisitPolicy.new(@tenant_admin, @visit_q).show?
  end

  test "tenant_admin can create, update, destroy visits" do
    assert VisitPolicy.new(@tenant_admin, @visit_p).create?
    assert VisitPolicy.new(@tenant_admin, @visit_p).update?
    assert VisitPolicy.new(@tenant_admin, @visit_p).destroy?
  end

  test "tenant_admin can authorize, check_in and check_out visits" do
    assert VisitPolicy.new(@tenant_admin, @visit_p).authorize?
    assert VisitPolicy.new(@tenant_admin, @visit_p).check_in?
    assert VisitPolicy.new(@tenant_admin, @visit_p).check_out?
  end

  test "tenant_admin cannot access visits from another organization" do
    refute VisitPolicy.new(@tenant_admin, @other_org_visit).show?
    refute VisitPolicy.new(@tenant_admin, @other_org_visit).check_in?
  end

  # ─── property_admin (assigned property only) ────────────────────────────────

  test "property_admin of P can index and show visits on P" do
    assert VisitPolicy.new(@property_admin_p, @visit_p).index?
    assert VisitPolicy.new(@property_admin_p, @visit_p).show?
  end

  test "property_admin of P can create and update visits on P" do
    assert VisitPolicy.new(@property_admin_p, @visit_p).create?
    assert VisitPolicy.new(@property_admin_p, @visit_p).update?
  end

  test "property_admin does not hold register_visit_entry or register_visit_exit" do
    # check_in/check_out are concierge-only capabilities (register_visit_entry/exit).
    # property_admin has manage_visits but that grants administrative control, not physical
    # check-in/out at the entrance. See Authorization::Capabilities::PROPERTY_ADMIN.
    refute VisitPolicy.new(@property_admin_p, @visit_p).check_in?
    refute VisitPolicy.new(@property_admin_p, @visit_p).check_out?
  end

  test "property_admin of P cannot manage visits on Q" do
    refute VisitPolicy.new(@property_admin_p, @visit_q).show?
    refute VisitPolicy.new(@property_admin_p, @visit_q).update?
    refute VisitPolicy.new(@property_admin_p, @visit_q).check_in?
    refute VisitPolicy.new(@property_admin_p, @visit_q).check_out?
  end

  # ─── concierge ──────────────────────────────────────────────────────────────

  test "concierge of P can show visits on P using view_authorized_visits" do
    assert VisitPolicy.new(@concierge_p, @visit_p).show?
  end

  test "concierge of P can check_in and check_out on P" do
    assert VisitPolicy.new(@concierge_p, @visit_p).check_in?
    assert VisitPolicy.new(@concierge_p, @visit_p).check_out?
  end

  test "concierge of P cannot create, update or authorize visits" do
    refute VisitPolicy.new(@concierge_p, @visit_p).create?
    refute VisitPolicy.new(@concierge_p, @visit_p).update?
    refute VisitPolicy.new(@concierge_p, @visit_p).authorize?
    refute VisitPolicy.new(@concierge_p, @visit_p).destroy?
  end

  test "concierge of P cannot access visits on Q" do
    refute VisitPolicy.new(@concierge_p, @visit_q).show?
    refute VisitPolicy.new(@concierge_p, @visit_q).check_in?
    refute VisitPolicy.new(@concierge_p, @visit_q).check_out?
  end

  # ─── owner / resident ────────────────────────────────────────────────────────

  test "owner can create visits for their unit via create_visits" do
    assert VisitPolicy.new(@owner, @visit_p).create?
  end

  test "owner cannot update or destroy visits" do
    refute VisitPolicy.new(@owner, @visit_p).update?
    refute VisitPolicy.new(@owner, @visit_p).destroy?
  end

  test "owner cannot check_in or check_out" do
    refute VisitPolicy.new(@owner, @visit_p).check_in?
    refute VisitPolicy.new(@owner, @visit_p).check_out?
  end

  test "resident can create visits for their unit via create_visits" do
    assert VisitPolicy.new(@resident, @visit_p).create?
  end

  test "resident cannot update, destroy, check_in or check_out" do
    refute VisitPolicy.new(@resident, @visit_p).update?
    refute VisitPolicy.new(@resident, @visit_p).destroy?
    refute VisitPolicy.new(@resident, @visit_p).check_in?
    refute VisitPolicy.new(@resident, @visit_p).check_out?
  end

  # ─── client without assignments ─────────────────────────────────────────────

  test "client without assignments cannot perform any visit action" do
    refute VisitPolicy.new(@client, @visit_p).index?
    refute VisitPolicy.new(@client, @visit_p).show?
    refute VisitPolicy.new(@client, @visit_p).create?
    refute VisitPolicy.new(@client, @visit_p).check_in?
    refute VisitPolicy.new(@client, @visit_p).check_out?
  end

  # ─── scope ──────────────────────────────────────────────────────────────────

  test "tenant_admin scope returns all visits in organization" do
    resolved = VisitPolicy::Scope.new(@tenant_admin, Visit.all).resolve

    assert_includes resolved, @visit_p
    assert_includes resolved, @visit_q
    refute_includes resolved, @other_org_visit
  end

  test "property_admin scope returns only visits on assigned property" do
    resolved = VisitPolicy::Scope.new(@property_admin_p, Visit.all).resolve

    assert_includes resolved, @visit_p
    refute_includes resolved, @visit_q
    refute_includes resolved, @other_org_visit
  end

  test "concierge scope returns only visits on assigned property" do
    resolved = VisitPolicy::Scope.new(@concierge_p, Visit.all).resolve

    assert_includes resolved, @visit_p
    refute_includes resolved, @visit_q
    refute_includes resolved, @other_org_visit
  end

  test "owner scope returns only visits on their unit" do
    resolved = VisitPolicy::Scope.new(@owner, Visit.all).resolve

    assert_includes resolved, @visit_p
    refute_includes resolved, @visit_q
    refute_includes resolved, @other_org_visit
  end

  test "client scope returns no visits" do
    assert_empty VisitPolicy::Scope.new(@client, Visit.all).resolve
  end

  # ─── capability contract assertions ─────────────────────────────────────────

  test "create_visits capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:create_visits)
  end

  test "authorize_visits capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:authorize_visits)
  end

  test "register_visit_entry capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:register_visit_entry)
  end

  test "register_visit_exit capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:register_visit_exit)
  end

  test "view_authorized_visits capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:view_authorized_visits)
  end

  test "view_minimal_access_control_data capability is defined in Authorization::Capabilities" do
    assert Authorization::Capabilities.known?(:view_minimal_access_control_data)
  end
end
