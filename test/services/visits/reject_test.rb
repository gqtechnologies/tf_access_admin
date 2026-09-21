# frozen_string_literal: true

require "test_helper"

module Visits
  # residential-visit-management "Pending visits can be rejected".
  class RejectTest < ActiveSupport::TestCase
    include OperationalPolicyTestHelper

    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      Current.organization = @organization

      @property = create_property(@organization, "Reject Property")
      @unit = create_unit(@property, "RJ-101")
      @resident = create_user_for_organization(
        organization: @organization, email: "rj-resident@example.test", role: AvailableRoles::CLIENT
      )
      UnitOccupancy.create!(
        organization: @organization, person: @resident.person_for(@organization), unit: @unit,
        occupancy_type: OccupancyTypes::TENANT, starts_at: 7.days.ago,
        status: OccupancyStatuses::ACTIVE, can_authorize_visits: true
      )
      @stranger = create_user_for_organization(
        organization: @organization, email: "rj-stranger@example.test", role: AvailableRoles::CLIENT
      )
      @concierge = create_staff_user(
        organization: @organization, email: "rj-concierge@example.test",
        staff_type: StaffTypes::CONCIERGE, property: @property
      )

      visitor = Person.create!(
        organization: @organization, display_name: "Rejected Visitor",
        person_type: PersonTypes::NATURAL, status: PersonStatuses::ACTIVE
      )
      @visit = Visit.create!(
        organization: @organization, unit: @unit, visitor_person: visitor,
        scheduled_at: 10.minutes.ago, status: VisitStatuses::PENDING, visit_type: VisitTypes::GUEST
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
      Current.reset
    end

    test "unit authorizer rejects a pending visit and history records it" do
      Reject.call(visit: @visit, actor: @resident, notes: "No lo conozco")

      assert_equal VisitStatuses::REJECTED, @visit.reload.status

      event = @visit.visit_status_histories.where(event_type: VisitEventTypes::REJECTED).last
      assert_equal VisitStatuses::PENDING, event.from_status
      assert_equal VisitStatuses::REJECTED, event.to_status
      assert_equal @resident.id, event.actor_user_id
      assert_equal "No lo conozco", event.notes
    end

    test "cannot reject an authorized visit" do
      @visit.update_columns(status: VisitStatuses::AUTHORIZED)

      assert_raises(Pundit::NotAuthorizedError) { Reject.call(visit: @visit, actor: @resident) }
      assert_equal VisitStatuses::AUTHORIZED, @visit.reload.status
    end

    test "user without capability on the unit cannot reject" do
      assert_raises(Pundit::NotAuthorizedError) { Reject.call(visit: @visit, actor: @stranger) }
      assert_equal VisitStatuses::PENDING, @visit.reload.status
    end

    test "rejected visit is not operational: hidden from the concierge scope and not checkable" do
      Reject.call(visit: @visit, actor: @resident)

      assert_not_includes VisitPolicy::Scope.new(@concierge, Visit).resolve, @visit
      assert_not @visit.reload.may_check_in?
    end
  end
end
