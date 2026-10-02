# frozen_string_literal: true

require "test_helper"

class Parcels::WithdrawTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ParcelTestHelper

  setup do
    setup_parcel_world("PW")
    @parcel = create_parcel(@unit)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "resident with the permission withdraws the parcel" do
    Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: person_of(@picker).id)

    @parcel.reload
    assert_equal ParcelStatuses::WITHDRAWN, @parcel.status
    assert_equal person_of(@picker).id, @parcel.withdrawn_by_person_id
    assert @parcel.withdrawn_at.present?

    history = @parcel.parcel_delivery_status_histories.sole
    assert_equal [ ParcelStatuses::RECEIVED, ParcelStatuses::WITHDRAWN ], [ history.from_status, history.to_status ]
    assert_equal person_of(@concierge).id, history.changed_by_person_id
  end

  test "occupant without the permission, owner and strangers are not eligible" do
    stranger = parcel_member("pw-stranger@example.test", "Stranger")

    [ @relative, @owner, stranger ].each do |user|
      assert_raises(Parcels::Withdraw::NotEligibleError) do
        Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: person_of(user).id)
      end
    end
    assert_raises(Parcels::Withdraw::NotEligibleError) do
      Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: nil)
    end

    assert_equal ParcelStatuses::RECEIVED, @parcel.reload.status
  end

  test "ended occupancy loses the permission" do
    UnitOccupancy.where(person: person_of(@picker)).update_all(ends_at: 2.days.ago)

    assert_raises(Parcels::Withdraw::NotEligibleError) do
      Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: person_of(@picker).id)
    end
  end

  test "an already withdrawn parcel cannot be withdrawn again" do
    Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: person_of(@picker).id)

    assert_raises(Parcels::Withdraw::NotWaitingError) do
      Parcels::Withdraw.call(parcel: @parcel, actor: @concierge, person_id: person_of(@picker).id)
    end
  end

  test "actor without manage_parcels on the property is rejected" do
    parcel_q = create_parcel(@unit_q)

    assert_raises(Pundit::NotAuthorizedError) do
      Parcels::Withdraw.call(parcel: parcel_q, actor: @concierge, person_id: person_of(@picker).id)
    end
    assert_raises(Pundit::NotAuthorizedError) do
      Parcels::Withdraw.call(parcel: @parcel, actor: @picker, person_id: person_of(@picker).id)
    end
  end
end
