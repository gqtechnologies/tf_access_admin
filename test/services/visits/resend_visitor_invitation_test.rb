# frozen_string_literal: true

require "test_helper"

module Visits
  # residential-visit-management "Resident resends the visitor invitation".
  class ResendVisitorInvitationTest < ActiveSupport::TestCase
    include OperationalPolicyTestHelper
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    KEY = ResendVisitorInvitation::METADATA_KEY

    setup do
      @organization = organizations(:one)
      ActsAsTenant.current_tenant = @organization
      Current.organization = @organization

      @property = create_property(@organization, "Resend Invitation Property")
      @unit = create_unit(@property, "RI-101")
      @host = create_user_for_organization(
        organization: @organization,
        email: "ri-host@example.test",
        role: AvailableRoles::CLIENT
      )

      person = Person.new(
        organization: @organization,
        display_name: "Resend Visitor",
        person_type: PersonTypes::NATURAL,
        status: PersonStatuses::ACTIVE
      )
      person.contact_email = "ri-visitor@example.test"
      person.save!

      @visit = Visit.create!(
        organization: @organization,
        unit: @unit,
        visitor_person: person,
        scheduled_at: 1.day.from_now,
        status: VisitStatuses::AUTHORIZED,
        visit_type: VisitTypes::GUEST,
        created_by: @host,
        authorized_by: @host
      )
    end

    teardown do
      ActsAsTenant.current_tenant = nil
      Current.reset
    end

    test "notifies the visitor, stamps metadata and records the event" do
      assert_enqueued_emails 1 do
        ResendVisitorInvitation.call(visit: @visit, actor: @host)
      end

      @visit.reload
      assert @visit.metadata[KEY].present?
      assert_equal VisitStatuses::AUTHORIZED, @visit.status

      event = @visit.visit_status_histories.where(event_type: VisitEventTypes::INVITATION_RESENT).last
      assert_equal @host.id, event.actor_user_id
      assert_equal VisitStatuses::AUTHORIZED, event.from_status
      assert_equal VisitStatuses::AUTHORIZED, event.to_status
    end

    test "preserves other metadata keys" do
      @visit.update_column(:metadata, { "vehicle" => { "plate" => "ABCD12" } })

      ResendVisitorInvitation.call(visit: @visit, actor: @host)

      assert_equal "ABCD12", @visit.reload.metadata.dig("vehicle", "plate")
      assert @visit.metadata[KEY].present?
    end

    test "does not touch resident notifications" do
      assert_no_difference -> { Notification.where(notification_type: NotificationTypes::VISIT_REQUEST).count } do
        ResendVisitorInvitation.call(visit: @visit, actor: @host)
      end

      assert_equal Visit::NotificationStatuses::PENDING, @visit.reload.notification_status
    end

    test "rejects a non-authorized visit" do
      @visit.update_columns(status: VisitStatuses::CANCELLED)

      assert_raises(ResendVisitorInvitation::NotResendableError) do
        ResendVisitorInvitation.call(visit: @visit, actor: @host)
      end
    end

    test "rejects an expired authorization" do
      @visit.update_columns(valid_from: 3.hours.ago, valid_until: 1.hour.ago)

      assert_raises(ResendVisitorInvitation::NotResendableError) do
        ResendVisitorInvitation.call(visit: @visit, actor: @host)
      end
    end

    test "enforces the cooldown and reports the remaining seconds" do
      ResendVisitorInvitation.call(visit: @visit, actor: @host)

      error = assert_raises(ResendVisitorInvitation::CooldownError) do
        ResendVisitorInvitation.call(visit: @visit.reload, actor: @host)
      end
      assert_in_delta 300, error.retry_after, 5
    end

    test "allows a new resend once the cooldown has passed" do
      @visit.update_column(:metadata, { KEY => 6.minutes.ago.iso8601 })

      assert ResendVisitorInvitation.resendable?(@visit)
      assert_nothing_raised { ResendVisitorInvitation.call(visit: @visit, actor: @host) }
    end

    test "a delivery failure still starts the cooldown" do
      with_failing_invite do
        assert_nothing_raised { ResendVisitorInvitation.call(visit: @visit, actor: @host) }
      end

      assert_not ResendVisitorInvitation.resendable?(@visit.reload)
    end

    private

    # Temporarily makes Accounts::InvitePerson.call_for_person raise (the visitor
    # has no account, so NotifyVisitor takes that branch).
    def with_failing_invite
      singleton = Accounts::InvitePerson.singleton_class
      original = singleton.instance_method(:call_for_person)
      singleton.define_method(:call_for_person) { |**| raise "boom" }
      yield
    ensure
      singleton.define_method(:call_for_person, original)
    end
  end
end
