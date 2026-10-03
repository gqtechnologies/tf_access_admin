# frozen_string_literal: true

require "test_helper"

class Reservations::DecideTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ReservationTestHelper
  include ActiveJob::TestHelper

  setup do
    setup_reservation_world("RD")
    @reservation = book
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "approving records who approved and pushes the outcome to the resident" do
    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      Reservations::Decide.call(reservation: @reservation, actor: @property_admin, decision: :approve)
    end

    @reservation.reload
    assert_equal ReservationStatuses::APPROVED, @reservation.status
    assert_equal person_of(@property_admin).id, @reservation.approved_by_person_id

    notification = @reservation.notifications.sole
    assert_equal person_of(@booker).id, notification.recipient_person_id
    payload = Notifications::PushPayload.build(notification)
    assert_equal "reservation", payload[:data][:type]
    assert_equal "approved", payload[:data][:status]
    assert_includes payload[:body], "Quincho"
  end

  test "rejecting stores the reason and tells the resident" do
    Reservations::Decide.call(reservation: @reservation, actor: @tenant_admin, decision: :reject, reason: "Día de mantención")

    @reservation.reload
    assert_equal ReservationStatuses::REJECTED, @reservation.status
    assert_equal "Día de mantención", @reservation.rejection_reason
    assert_includes Notifications::PushPayload.build(@reservation.notifications.sole)[:body], "Día de mantención"
  end

  test "only pending reservations are decided, and only by the administration" do
    assert_raises(Pundit::NotAuthorizedError) do
      Reservations::Decide.call(reservation: @reservation, actor: @concierge, decision: :approve)
    end

    Reservations::Decide.call(reservation: @reservation, actor: @tenant_admin, decision: :approve)
    assert_raises(Reservations::Decide::NotPending) do
      Reservations::Decide.call(reservation: @reservation, actor: @tenant_admin, decision: :reject)
    end
  end

  test "the resident cancels their own booking without a push; the administration's cancel pushes" do
    assert_no_enqueued_jobs only: DeliverPushNotificationJob do
      Reservations::Cancel.call(reservation: @reservation, actor: @booker)
    end
    assert_equal ReservationStatuses::CANCELLED, @reservation.reload.status

    other = book(from: local_at(4, 18), to: local_at(4, 20))
    assert_enqueued_jobs 1, only: DeliverPushNotificationJob do
      Reservations::Cancel.call(reservation: other, actor: @tenant_admin, reason: "Corte de luz")
    end
  end

  test "someone else cannot cancel, and a cancelled booking cannot be cancelled again" do
    assert_raises(Pundit::NotAuthorizedError) { Reservations::Cancel.call(reservation: @reservation, actor: @relative) }

    Reservations::Cancel.call(reservation: @reservation, actor: @booker)
    assert_raises(Reservations::Cancel::NotCancellable) { Reservations::Cancel.call(reservation: @reservation, actor: @booker) }
  end
end
