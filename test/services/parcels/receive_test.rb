# frozen_string_literal: true

require "test_helper"

class Parcels::ReceiveTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ParcelTestHelper
  include ActiveJob::TestHelper

  setup { setup_parcel_world("PR") }

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "registers the parcel with history and notifies the whole unit once per person" do
    # The owner also lives there: still a single notification for them.
    parcel_occupy(@owner, @unit, type: OccupancyTypes::OWNER_RESIDENT)

    parcel = nil
    assert_enqueued_jobs 3, only: DeliverPushNotificationJob do
      parcel = Parcels::Receive.call(
        unit: @unit, actor: @concierge,
        attributes: { delivery_type: DeliveryTypes::FOOD, courier_company: " Rappi ", notes: "Bolsa" }
      )
    end

    assert parcel.persisted?
    assert_equal ParcelStatuses::RECEIVED, parcel.status
    assert_equal DeliveryTypes::FOOD, parcel.delivery_type
    assert_equal "Rappi", parcel.courier_company
    assert_equal @property.id, parcel.residential_property_id
    assert_equal person_of(@concierge).id, parcel.received_by_person_id
    assert parcel.received_at.present?
    assert parcel.reload.notified_at.present?

    history = parcel.parcel_delivery_status_histories.sole
    assert_nil history.from_status
    assert_equal ParcelStatuses::RECEIVED, history.to_status

    recipients = parcel.notifications.map(&:recipient_person_id)
    assert_equal [ @picker, @relative, @owner ].map { |u| person_of(u).id }.sort, recipients.sort
    assert parcel.notifications.all? { |n| n.notification_type == NotificationTypes::PARCEL }
  end

  test "defaults the delivery type to parcel" do
    parcel = Parcels::Receive.call(unit: @unit, actor: @concierge)

    assert_equal DeliveryTypes::PARCEL, parcel.delivery_type
  end

  test "unit without residents is registered without notifications" do
    empty_unit = create_unit(@property, "PR-P-EMPTY")

    parcel = nil
    assert_no_enqueued_jobs only: DeliverPushNotificationJob do
      parcel = Parcels::Receive.call(unit: empty_unit, actor: @concierge)
    end

    assert parcel.persisted?
    assert_nil parcel.reload.notified_at
  end

  test "invalid delivery type raises and stores nothing" do
    assert_no_difference "ParcelDelivery.count" do
      assert_raises(ActiveRecord::RecordInvalid) do
        Parcels::Receive.call(unit: @unit, actor: @concierge, attributes: { delivery_type: "piano" })
      end
    end
  end

  test "actor without manage_parcels on the property is rejected" do
    assert_no_difference "ParcelDelivery.count" do
      assert_raises(Pundit::NotAuthorizedError) { Parcels::Receive.call(unit: @unit_q, actor: @concierge) }
      assert_raises(Pundit::NotAuthorizedError) { Parcels::Receive.call(unit: @unit, actor: @picker) }
    end
  end

  test "push payload names the delivery and the unit" do
    parcel = Parcels::Receive.call(unit: @unit, actor: @concierge)
    payload = Notifications::ParcelPushPayload.build(parcel.notifications.first)

    assert_equal I18n.t("notifications.parcel.title", locale: :es), payload[:title]
    assert_includes payload[:body], "PR-P-101"
    assert_equal "parcel", payload[:data][:type]
    assert_equal parcel.id, payload[:data][:parcel_id]
    assert_equal @unit.id, payload[:data][:unit_id]
  end
end
