# frozen_string_literal: true

require "test_helper"

class ParcelDeliveryPolicyTest < ActiveSupport::TestCase
  include OperationalPolicyTestHelper
  include ParcelTestHelper

  setup do
    setup_parcel_world("PP")
    @parcel   = create_parcel(@unit)
    @parcel_q = create_parcel(@unit_q)
  end

  teardown do
    ActsAsTenant.current_tenant = nil
    Current.reset
  end

  test "concierge manages parcels of the assigned property only" do
    assert ParcelDeliveryPolicy.new(@concierge, @parcel).create?
    assert ParcelDeliveryPolicy.new(@concierge, @parcel).withdraw?
    assert_not ParcelDeliveryPolicy.new(@concierge, @parcel_q).withdraw?

    assert_equal [ @parcel ], ParcelDeliveryPolicy::Scope.new(@concierge, ParcelDelivery).resolve.to_a
  end

  test "tenant admin manages every property" do
    admin = create_user_for_organization(
      organization: @organization, email: "pp-admin@example.test", role: AvailableRoles::TENANT_ADMIN
    )

    assert ParcelDeliveryPolicy.new(admin, @parcel_q).withdraw?
    assert_equal [ @parcel.id, @parcel_q.id ].sort,
      ParcelDeliveryPolicy::Scope.new(admin, ParcelDelivery).resolve.pluck(:id).sort
  end

  test "resident holds no parcel capability" do
    assert_not ParcelDeliveryPolicy.new(@picker, @parcel).show?
    assert_not ParcelDeliveryPolicy.new(@picker, ParcelDelivery).index?
    assert_empty ParcelDeliveryPolicy::Scope.new(@picker, ParcelDelivery).resolve
  end
end
