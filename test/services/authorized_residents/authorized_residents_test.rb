# frozen_string_literal: true

require "test_helper"

class AuthorizedResidentsServicesTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_reservation_world("AR")
    # The picker may authorize visits; the relative may not.
    UnitOccupancy.where(person: person_of(@picker)).update_all(can_authorize_visits: true)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "an authorizing occupant proposes someone, pending until approved" do
    record = propose(@picker)

    assert_equal AuthorizedResidentStatuses::PENDING, record.status
    assert_equal "Nora Nana", record.person.display_name
    assert_equal "22.333.444-5", record.person.document_number
    assert_equal person_of(@picker).id, record.authorized_by_person_id
    assert record.can_withdraw_parcels
    assert_not AuthorizedResident.currently_valid.exists?(record.id)
  end

  test "owners propose too; occupants without the visit permission and strangers cannot" do
    assert propose(@owner, email: "chofer@example.test", name: "Carlos Chofer", document: "9.888.777-6").persisted?

    assert_raises(AuthorizedResidents::Propose::NotAllowed) { propose(@relative, email: "x@example.test", document: "1-9") }
    assert_raises(AuthorizedResidents::Propose::NotAllowed) do
      propose(parcel_member("ar-stranger@example.test", "Stranger"), email: "y@example.test", document: "2-7")
    end
  end

  test "the same person cannot be listed twice while open" do
    propose(@picker)

    assert_raises(AuthorizedResidents::Propose::AlreadyListed) { propose(@owner) }
  end

  test "approval makes them valid, eligible for parcels, and tells the proposer" do
    record = propose(@picker)

    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      AuthorizedResidents::Decide.call(authorized_resident: record, actor: @property_admin, decision: :approve)
    end

    assert AuthorizedResident.currently_valid.exists?(record.id)
    assert Parcels::EligibleWithdrawers.include?(unit: @unit, person_id: record.person_id)

    payload = Notifications::PushPayload.build(record.notifications.sole)
    assert_equal "authorized_person", payload[:data][:type]
    assert_includes payload[:body], "Nora Nana"
  end

  test "an expired authorization no longer counts" do
    record = propose(@picker, ends_at: Date.current.iso8601)
    AuthorizedResidents::Decide.call(authorized_resident: record, actor: @tenant_admin, decision: :approve)
    record.update_columns(starts_at: 2.days.ago, ends_at: 1.minute.ago)

    assert_not Parcels::EligibleWithdrawers.include?(unit: @unit, person_id: record.person_id)
  end

  test "rejecting, revoking and withdrawing follow their transitions" do
    rejected = propose(@picker)
    AuthorizedResidents::Decide.call(authorized_resident: rejected, actor: @tenant_admin, decision: :reject)
    assert_equal AuthorizedResidentStatuses::REJECTED, rejected.reload.status
    assert_raises(AuthorizedResidents::Decide::InvalidTransition) do
      AuthorizedResidents::Decide.call(authorized_resident: rejected, actor: @tenant_admin, decision: :revoke)
    end

    approved = propose(@picker, email: "otra@example.test", name: "Otra", document: "3-5")
    AuthorizedResidents::Decide.call(authorized_resident: approved, actor: @tenant_admin, decision: :approve)
    AuthorizedResidents::Withdraw.call(authorized_resident: approved, person: person_of(@owner))
    assert_equal AuthorizedResidentStatuses::REVOKED, approved.reload.status
    assert approved.ends_at.present?
  end

  test "only those who manage the unit's residents decide" do
    record = propose(@picker)

    [ @concierge, @picker ].each do |actor|
      assert_raises(Pundit::NotAuthorizedError) do
        AuthorizedResidents::Decide.call(authorized_resident: record, actor: actor, decision: :approve)
      end
    end
  end

  private

  def propose(user, email: "nana@example.test", name: "Nora Nana", document: "22.333.444-5", ends_at: nil)
    AuthorizedResidents::Propose.call(
      unit: @unit, proposer: person_of(user),
      person_params: { name: name, email: email, document: document },
      attributes: { relationship_type: "staff", can_withdraw_parcels: true, ends_at: ends_at }
    )
  end
end
