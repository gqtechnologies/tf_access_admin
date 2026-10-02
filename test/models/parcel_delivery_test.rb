# frozen_string_literal: true

require "test_helper"

class ParcelDeliveryTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ParcelTestHelper

  setup { setup_parcel_world("PM") }

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "rejects unknown status and delivery type" do
    parcel = create_parcel(@unit)

    parcel.status = "lost"
    assert_not parcel.valid?

    parcel.status = ParcelStatuses::RECEIVED
    parcel.delivery_type = "piano"
    assert_not parcel.valid?
  end

  test "blank text fields are stored as nil" do
    parcel = create_parcel(@unit, courier_company: "  ", tracking_code: " ABC-1 ")

    assert_nil parcel.courier_company
    assert_equal "ABC-1", parcel.tracking_code
  end

  test "waiting and recently_withdrawn scopes" do
    waiting = create_parcel(@unit)
    recent  = create_parcel(@unit, status: ParcelStatuses::WITHDRAWN, received_at: 3.days.ago, withdrawn_at: 2.days.ago)
    old     = create_parcel(@unit, status: ParcelStatuses::WITHDRAWN, received_at: 50.days.ago, withdrawn_at: 40.days.ago)

    assert_equal [ waiting ], ParcelDelivery.waiting.to_a
    assert_equal [ recent ], ParcelDelivery.recently_withdrawn.to_a
    assert_not_includes ParcelDelivery.recently_withdrawn, old
  end
end
